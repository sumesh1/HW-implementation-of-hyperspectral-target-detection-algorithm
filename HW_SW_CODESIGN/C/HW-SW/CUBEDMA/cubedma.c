/*
 * cubedma.c
 *
 *  Created on: 17. sep. 2018
 *      Author: Lars Henrik Bolstad
 */

#include "cubedma.h"
#include <xil_io.h>  /* TODO: Remove after debug */
#include <stdio.h>   /* Ditto */
#include <xil_cache.h>

#define CUBEDMA_BASE 0x43C10000

/* TODO: Add CUBEDMA_ prefix, fill out (or remove) */
#define MM2S_OFFSET		0x00
#define MM2S_CR_OFFSET		0x00
#define MM2S_SR_OFFSET		0x04
#define MM2S_BASADDR_OFFSET	0x08
#define MM2S_DIM1_OFFSET	0x0C
#define MM2S_DIM2_OFFSET	0x10
#define MM2S_ROWSIZE_OFFSET	0x14

#define S2MM_OFFSET		0x20
#define S2MM_CR_OFFSET		0x00
#define S2MM_SR_OFFSET		0x04
#define S2MM_BASADDR_OFFSET	0x08
#define S2MM_RXLEN_OFFSET	0x0C

#define SR_DONE_MSK			1U

#define SR_ERR_INT_MSK		1U
#define SR_ERR_DEC_MSK		2U
#define SR_ERR_SLV_MSK		4U

#define CR_OFFSET(mode) (mode==MM2S)? \
		(MM2S_OFFSET|MM2S_CR_OFFSET): \
		(S2MM_OFFSET|S2MM_CR_OFFSET)

#define SR_OFFSET(mode) (mode==MM2S)? \
		(MM2S_OFFSET|MM2S_SR_OFFSET): \
		(S2MM_OFFSET|S2MM_SR_OFFSET)

typedef struct {
	/* FIXME: 64-bit alignment issue for dims-registers.
	 * A 64-bit value is apparently misaligned when following
	 * an odd number of 32-bit values. Because of this, dims
	 * are separated into two 32-bit values (dims_l, dims_h).
	 */
	struct {				/**Memory to Stream***/
		u32 cr;				/* Control Register  */
		u32 sr;				/* Status Register   */
		u32 baseaddr;		/* Send address      */
		u32 dims_l;			/* Dimensions (LSBs) */
		u32 dims_h;			/* Dimensions (MSBs) */
		u32 rowsize;		/* Size of cube rows */
	} mm2s;
	const u64 _reserverd;
	struct {				/**Stream to Memory**/
		u32 cr;				/* Control Register */
		u32 sr;				/* Status Register  */
		u32 baseaddr;		/* Receive address  */
		u32 rclength;		/* Bytes received   */
	} s2mm;
} dma_regs_t;

volatile dma_regs_t* dma __attribute__ ((aligned (32)));

/* FIXME: Are 8-bit reads more efficient? */
#define cubedma_RegWrite(offset, val) \
	Xil_Out32((u32)(dma)|(offset), val)

#define cubedma_RegRead(offset) \
	Xil_In32((u32)(dma)|(offset))

#define cubedma_RegSet(offset, val) \
	cubedma_RegWrite(offset, cubedma_RegRead(offset)|(val))

/* FIXME: Clear interrupts */
void cubedma_ClearInterrupts(){
	cubedma_RegWrite(SR_OFFSET(MM2S), 3U << 4); // 0011 0000
	cubedma_RegWrite(SR_OFFSET(S2MM), 3U << 4);
}

cubedma_error_t cubedma_Init(cubedma_init_t param){
	dma = (dma_regs_t*)CUBEDMA_BASE;

	/* TODO: Fix magic numbers */
	/* TODO: Assert valid parameters */
	/* FIXME: Enable safe-write */
	/* FIXME: Write zero before initialization */

	dma->mm2s.cr = \
			(param.cube.blocks.enabled & 1U) << 2 \
			| (param.cube.planewise & 1U) << 3 \
			| (param.interrupt_enable.mm2s.error & 1) << 4 \
			| (param.interrupt_enable.mm2s.complete & 1) << 5 \
			| (param.cube.n_planes & 0xFF) << 8 \
			| (param.cube.c_offset & 0xFF) << 16;

	dma->mm2s.baseaddr = param.address.source;

	dma->mm2s.dims_l = \
			(param.cube.dims.width & 0xFFF) \
			| (param.cube.dims.height & 0xFFF) << 12 \
			| (param.cube.dims.depth & 0xFF) << 24;

	dma->mm2s.dims_h = \
			(param.cube.blocks.dims.width & 0xF) \
			| (param.cube.blocks.dims.height & 0xF) << 4 \
			| ((param.cube.dims.depth >> 8U) & 0xF) << 8 \
			| (param.cube.blocks.dims.size_last_row & 0xFFFFF) << 12;

	dma->mm2s.rowsize = param.cube.dims.size_row;

	dma->s2mm.cr = \
			(param.interrupt_enable.s2mm.error & 1U) << 4 \
			| (param.interrupt_enable.s2mm.complete & 1U) << 5;

	dma->s2mm.baseaddr = param.address.destination;

	//cubedma_ClearInterrupts();

	return SUCCESS;
}

static inline u32 cubedma_TransferLength(){
	u32 w = dma->mm2s.dims_l & 0xFFF;
	u32 h = (dma->mm2s.dims_l >> 12) & 0xFFF;
	u32 d = ((dma->mm2s.dims_l >> 24) & 0xFF) & (dma->mm2s.dims_h & 0xF00);
	u32 r = dma->mm2s.rowsize;
	return w*h*d*r;
}

/* TODO: polling/interrupt */

cubedma_error_t cubedma_StartTransfer(transfer_t transfer){

	switch (transfer) {
	case MM2S:
		/* FIXME: Do sizeof() properly return the size of the components? */
		Xil_DCacheFlushRange((INTPTR)dma->mm2s.baseaddr,
				cubedma_TransferLength()*sizeof(dma->mm2s.baseaddr));
		break;
	case S2MM:
		break;
	default:
		return ERR_INV_PARAM;
	}

	/* TODO: Clean up this mess */

	/* Started, but not done? */
	if ((cubedma_RegRead(CR_OFFSET(transfer))&1U) \
		&& !(cubedma_RegRead(SR_OFFSET(transfer))&1U)) {

		return ERR_BUSY;
	}

	/* Start transfer */
	/* TODO: Fix magic number (start bit) */
	cubedma_RegSet(CR_OFFSET(transfer), 1U);

	return SUCCESS;

	/* ---mess--- */
}

cubedma_interrupt_t cubedma_ReadInterrupts(transfer_t transfer) {
	cubedma_interrupt_t flags = (cubedma_interrupt_t)( \
			(cubedma_RegRead(SR_OFFSET(transfer)) >> 4) & 3U); //magic
	switch ((cubedma_interrupt_t)flags){
	case COMPLETE:
		return COMPLETE;
	case NONE:
		return NONE;
	default:
		return ERROR; // 11 or 01
	}
}

/**
Make sure the (potentially) cached CubeDMA AXI memory do not deviate from
system memory.
*/
static inline void cubedma_RefreshStatus() {
	/* FIXME: Is this at all necessary? */
	/* FIXME: Is this (AXI memory) D-cache or I-cache? */
	/* FIXME: Magic numbers, 12 = number of u32s in dma */
	Xil_DCacheInvalidateRange((INTPTR)dma, 12*sizeof(u32));
}

u8 cubedma_TransferDone(transfer_t transfer){
	cubedma_RefreshStatus();
	if (cubedma_RegRead(SR_OFFSET(transfer)) & SR_DONE_MSK) {
		if (transfer == S2MM) {
			Xil_DCacheInvalidateRange(
					(INTPTR)dma->s2mm.baseaddr, dma->s2mm.rclength);
		}
		return TRUE;
	}
	return FALSE;
}

void dbg_cmp_mem(u32 b[]){
	u32 a[12] = {
		0x00000101,
		0x00000021,
		0x00100000,
		0x01001001,
		0x00000000,
		0x00000010,
		0x00000000,
		0x00000000,
		0x00000001,
		0x00000021,
		0x00200000,
		0x00000040
	};
	for (u32 i = 0; i < 12; i++){
		printf("%02lx: %08lx %08lx", i*4, a[i], b[i]);
		if (a[i]==b[i]) {
			printf(" ok\n\r");
		}
		else {
			printf(" different\n\r");
		}
	}
}
