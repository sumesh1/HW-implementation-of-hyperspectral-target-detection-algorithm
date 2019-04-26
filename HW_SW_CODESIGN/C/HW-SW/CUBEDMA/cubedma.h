/*
 * cubedma.h
 *
 *  Created on: 17. sep. 2018
 *      Author: Lars
 */

#ifndef SRC_CUBEDMA_H_
#define SRC_CUBEDMA_H_

#include <xil_types.h>

typedef enum {
	SUCCESS,
	ERR_TIMEOUT,
	ERR_BUSY,
	ERR_INV_PARAM
} cubedma_error_t;

typedef enum {
	MM2S,
	S2MM
} transfer_t;

typedef enum {
	NONE = 0,
	ERROR = 1,
	COMPLETE = 2
} cubedma_interrupt_t;

typedef struct {
	u8 error:1;
	u8 complete:1;
} cubedma_init_enable_irq_t;

typedef struct {
	struct{
		u32 source;
		u32 destination;
	} address;
	struct {
		u8 n_planes;
		u8 c_offset;
		u8 planewise:1;
		struct {
			u8 enabled:1;
			struct {
				u8 width:4;
				u8 height:4;
				u32 size_last_row:20;
			} dims;
		} blocks;
		struct {
			u16 width:12;
			u16 height:12;
			u16 depth:12;
			u32 size_row:20;
		} dims;
	} cube;
	struct {
		cubedma_init_enable_irq_t mm2s;
		cubedma_init_enable_irq_t s2mm;
	} interrupt_enable;
} cubedma_init_t;

cubedma_error_t cubedma_Init(cubedma_init_t param);
cubedma_error_t cubedma_StartTransfer(transfer_t transfer);
cubedma_interrupt_t cubedma_ReadInterrupts(transfer_t transfer);
u8 cubedma_TransferDone(transfer_t transfer);

#endif /* SRC_CUBEDMA_H_ */
