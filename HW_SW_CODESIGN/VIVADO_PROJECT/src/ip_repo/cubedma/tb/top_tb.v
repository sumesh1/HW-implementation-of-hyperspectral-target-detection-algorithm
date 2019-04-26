`timescale 1ns/1ps

module top_tb;
   parameter IN_WIDTH = 8;
   parameter IN_NUM_COMP = 1;
   parameter IN_BUS_WIDTH = IN_WIDTH * IN_NUM_COMP;
   parameter OUT_WIDTH = 8;
   parameter OUT_NUM_COMP = 1;
   parameter OUT_BUS_WIDTH = OUT_WIDTH * OUT_NUM_COMP;
   parameter TINYMOVER = 0;
   parameter PERIOD = 10;

   reg clk, aresetn;

   wire [31:0] m_axi_mem_araddr;
   wire [3:0] m_axi_mem_arlen;
   wire [2:0] m_axi_mem_arsize;
   wire [1:0] m_axi_mem_arburst;
   wire [2:0] m_axi_mem_arprot;
   wire [3:0] m_axi_mem_arcache;
   wire m_axi_mem_arvalid;
   wire m_axi_mem_arready;
   wire [63:0] m_axi_mem_rdata;
   wire [1:0] m_axi_mem_rresp;
   wire m_axi_mem_rlast;
   wire m_axi_mem_rvalid;
   wire m_axi_mem_rready;
   wire[31:0] m_axi_mem_awaddr;    // input wire [31 : 0] s_axi_awaddr
   wire[3:0] m_axi_mem_awlen;      // input wire [7 : 0] s_axi_awlen
   wire[2:0] m_axi_mem_awsize;    // input wire [2 : 0] s_axi_awsize
   wire[1:0] m_axi_mem_awburst;  // input wire [1 : 0] s_axi_awburst
   wire m_axi_mem_awvalid;  // input wire s_axi_awvalid
   wire m_axi_mem_awready;  // output wire s_axi_awready
   wire[63:0] m_axi_mem_wdata;      // input wire [63 : 0] s_axi_wdata
   wire[7:0] m_axi_mem_wstrb;      // input wire [7 : 0] s_axi_wstrb
   wire m_axi_mem_wlast;      // input wire s_axi_wlast
   wire m_axi_mem_wvalid;    // input wire s_axi_wvalid
   wire m_axi_mem_wready;    // output wire s_axi_wready
   wire [1:0] m_axi_mem_bresp;      // output wire [1 : 0] s_axi_bresp
   wire m_axi_mem_bvalid;    // output wire s_axi_bvalid
   wire m_axi_mem_bready;    // input wire s_axi_bready

   wire [IN_BUS_WIDTH-1:0] m_axis_mm2s_tdata;
   wire m_axis_mm2s_tlast;
   wire m_axis_mm2s_tvalid;
   reg m_axis_mm2s_tready;

   reg [OUT_BUS_WIDTH-1:0] s2mm_tdata;
   reg s2mm_tlast;
   reg s2mm_tvalid;
   wire s2mm_tready;

   reg [5:0] s_axi_ctrl_status_awaddr;
   reg [2:0] s_axi_ctrl_status_awprot;
   reg s_axi_ctrl_status_awvalid;
   wire s_axi_ctrl_status_awready;
   reg [31:0] s_axi_ctrl_status_wdata;
   reg [3:0] s_axi_ctrl_status_wstrb;
   reg s_axi_ctrl_status_wvalid;
   wire s_axi_ctrl_status_wready;
   wire [1:0] s_axi_ctrl_status_bresp;
   wire s_axi_ctrl_status_bvalid;
   reg s_axi_ctrl_status_bready;

   wire mm2s_irq;
   wire s2mm_irq;

   integer i;

   // Block RAM for DataMover to read from.
   // The Block RAM is given initial data through a COE file.
   blk_mem_tb i_bram
     (
      .s_aclk(clk),                // input wire s_aclk
      .s_aresetn(aresetn),          // input wire s_aresetn
      .s_axi_awid(4'b0),        // input wire [3 : 0] s_axi_awid
      .s_axi_awaddr(m_axi_mem_awaddr),    // input wire [31 : 0] s_axi_awaddr
      .s_axi_awlen({4'b0, m_axi_mem_awlen}),      // input wire [7 : 0] s_axi_awlen
      .s_axi_awsize(m_axi_mem_awsize),    // input wire [2 : 0] s_axi_awsize
      .s_axi_awburst(m_axi_mem_awburst),  // input wire [1 : 0] s_axi_awburst
      .s_axi_awvalid(m_axi_mem_awvalid),  // input wire s_axi_awvalid
      .s_axi_awready(m_axi_mem_awready),  // output wire s_axi_awready
      .s_axi_wdata(m_axi_mem_wdata),      // input wire [63 : 0] s_axi_wdata
      .s_axi_wstrb(m_axi_mem_wstrb),      // input wire [7 : 0] s_axi_wstrb
      .s_axi_wlast(m_axi_mem_wlast),      // input wire s_axi_wlast
      .s_axi_wvalid(m_axi_mem_wvalid),    // input wire s_axi_wvalid
      .s_axi_wready(m_axi_mem_wready),    // output wire s_axi_wready
      .s_axi_bresp(m_axi_mem_bresp),      // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid(m_axi_mem_bvalid),    // output wire s_axi_bvalid
      .s_axi_bready(m_axi_mem_bready),    // input wire s_axi_bready

      .s_axi_arid(4'b0),        // input wire [3 : 0] s_axi_arid
      .s_axi_araddr(m_axi_mem_araddr),    // input wire [31 : 0] s_axi_araddr
      .s_axi_arlen({4'b0, m_axi_mem_arlen}),      // input wire [7 : 0] s_axi_arlen
      .s_axi_arsize(m_axi_mem_arsize),    // input wire [2 : 0] s_axi_arsize
      .s_axi_arburst(m_axi_mem_arburst),  // input wire [1 : 0] s_axi_arburst
      .s_axi_arvalid(m_axi_mem_arvalid),  // input wire s_axi_arvalid
      .s_axi_arready(m_axi_mem_arready),  // output wire s_axi_arready
      .s_axi_rid(m_axi_mem_rid),          // output wire [3 : 0] s_axi_rid
      .s_axi_rdata(m_axi_mem_rdata),      // output wire [63 : 0] s_axi_rdata
      .s_axi_rresp(m_axi_mem_rresp),      // output wire [1 : 0] s_axi_rresp
      .s_axi_rlast(m_axi_mem_rlast),      // output wire s_axi_rlast
      .s_axi_rvalid(m_axi_mem_rvalid),    // output wire s_axi_rvalid
      .s_axi_rready(m_axi_mem_rready)    // input wire s_axi_rready
      );

   cubedma_top #(
       .C_MM2S_AXIS_WIDTH(IN_BUS_WIDTH),
       .C_MM2S_COMP_WIDTH(IN_WIDTH),
       .C_MM2S_NUM_COMP(IN_NUM_COMP),
       .C_TINYMOVER(TINYMOVER),
       .C_S2MM_AXIS_WIDTH(OUT_BUS_WIDTH),
       .C_S2MM_COMP_WIDTH(OUT_WIDTH),
       .C_S2MM_NUM_COMP(OUT_NUM_COMP)
   ) i_dut (
      .clk(clk),
      .aresetn(aresetn),

      .m_axi_mem_araddr(m_axi_mem_araddr),
      .m_axi_mem_arlen(m_axi_mem_arlen),
      .m_axi_mem_arsize(m_axi_mem_arsize),
      .m_axi_mem_arburst(m_axi_mem_arburst),
      .m_axi_mem_arprot(m_axi_mem_arprot),
      .m_axi_mem_arcache(m_axi_mem_arcache),
      .m_axi_mem_arvalid(m_axi_mem_arvalid),
      .m_axi_mem_arready(m_axi_mem_arready),
      .m_axi_mem_rdata(m_axi_mem_rdata),
      .m_axi_mem_rresp(m_axi_mem_rresp),
      .m_axi_mem_rlast(m_axi_mem_rlast),
      .m_axi_mem_rvalid(m_axi_mem_rvalid),
      .m_axi_mem_rready(m_axi_mem_rready),

            .m_axi_mem_awaddr(m_axi_mem_awaddr),
            .m_axi_mem_awlen(m_axi_mem_awlen),
            .m_axi_mem_awsize(m_axi_mem_awsize),
            .m_axi_mem_awburst(m_axi_mem_awburst),
            .m_axi_mem_awprot(m_axi_mem_awprot),
            .m_axi_mem_awcache(m_axi_mem_awcache),
            .m_axi_mem_awvalid(m_axi_mem_awvalid),
            .m_axi_mem_awready(m_axi_mem_awready),
            .m_axi_mem_wdata(m_axi_mem_wdata),
            .m_axi_mem_wstrb(m_axi_mem_wstrb),
            .m_axi_mem_wlast(m_axi_mem_wlast),
            .m_axi_mem_wvalid(m_axi_mem_wvalid),
            .m_axi_mem_wready(m_axi_mem_wready),
            .m_axi_mem_bresp(m_axi_mem_bresp),
            .m_axi_mem_bvalid(m_axi_mem_bvalid),
            .m_axi_mem_bready(m_axi_mem_bready),

      .m_axis_mm2s_tdata(m_axis_mm2s_tdata),
      .m_axis_mm2s_tlast(m_axis_mm2s_tlast),
      .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),
      .m_axis_mm2s_tready(m_axis_mm2s_tready),

      .s_axis_s2mm_tdata(s2mm_tdata),
      .s_axis_s2mm_tlast(s2mm_tlast),
      .s_axis_s2mm_tvalid(s2mm_tvalid),
      .s_axis_s2mm_tready(s2mm_tready),

      .s_axi_ctrl_status_awaddr(s_axi_ctrl_status_awaddr),
      .s_axi_ctrl_status_awprot(s_axi_ctrl_status_awprot),
      .s_axi_ctrl_status_awvalid(s_axi_ctrl_status_awvalid),
      .s_axi_ctrl_status_awready(s_axi_ctrl_status_awready),
      .s_axi_ctrl_status_wdata(s_axi_ctrl_status_wdata),
      .s_axi_ctrl_status_wstrb(s_axi_ctrl_status_wstrb),
      .s_axi_ctrl_status_wvalid(s_axi_ctrl_status_wvalid),
      .s_axi_ctrl_status_wready(s_axi_ctrl_status_wready),
      .s_axi_ctrl_status_bresp(s_axi_ctrl_status_bresp),
      .s_axi_ctrl_status_bvalid(s_axi_ctrl_status_bvalid),
      .s_axi_ctrl_status_bready(s_axi_ctrl_status_bready),

      .mm2s_irq(mm2s_irq),
      .s2mm_irq(s2mm_irq));

   always #(PERIOD/2) clk = ~clk;


   parameter N_FILL = 10920;
   integer idx;

   initial begin
      clk <= 1'b0;
      aresetn <= 1'b0;

      s_axi_ctrl_status_awprot <= 'b0;
      s_axi_ctrl_status_bready <= 1'b0;
      s_axi_ctrl_status_wstrb <= 4'hF;
      m_axis_mm2s_tready <= 1'b1;

      repeat(4) @(posedge clk);
      aresetn <= 1'b1;

      initiate_simple_transfer(1, 0);

      write_to_reg(6'h28, 32'h000);
      idx = 0;
      s2mm_tlast <= 1'b0;
      s2mm_tvalid <= 1'b1;
      while (idx < N_FILL) begin
         s2mm_tdata <= idx;// / 16;
         if (idx == N_FILL - 1) begin
            s2mm_tlast <= 1'b1;
         end
         if (s2mm_tready === 1'b1) begin
            idx = idx + 1;
         end
         @(posedge clk);
      end
      s2mm_tvalid <= 1'b0;

      @(posedge s2mm_irq);
      ack_irq(1'b0);

      initiate_transfer(0, 0, 1, 1, 10, 10, 10, 2, 2, 0, 100, 0);
      @(posedge mm2s_irq);
      ack_irq(1'b0);

   end // initial begin

   task write_to_reg;
      input [5:0] address;
      input [31:0] data;
      begin
         @(posedge clk);
         s_axi_ctrl_status_awaddr <= address;
         s_axi_ctrl_status_awvalid <= 1'b1;
         s_axi_ctrl_status_wvalid <= 1'b1;
         s_axi_ctrl_status_wdata <= data;

         while (!(s_axi_ctrl_status_awready == 1'b1 && s_axi_ctrl_status_wready == 1'b1)) begin
            @(posedge clk);
         end

         s_axi_ctrl_status_awvalid <= 1'b0;
         s_axi_ctrl_status_wvalid <= 1'b0;
      end
   endtask

   task initiate_simple_transfer;
      input base;
      input [19:0] length;
      begin
         initiate_transfer(base, 0, 0, 0, 1, 1, 1, 0, 0, 0, length, 1);
      end
   endtask // initiate_transfer

   task initiate_transfer;
      input base;
      input offset;
      input [0:0] mode_block;
      input [0:0] mode_plane;
      input [11:0] width;
      input [11:0] height;
      input [7:0]  depth;
      input [3:0] block_width;
      input [3:0] block_height;
      input [19:0] last_block_row_length;
      input [19:0] line_skip;
      input [7:0]  plane_transfers;
      begin
         write_to_reg({base,5'h0C}, {depth, height, width});
         write_to_reg({base,5'h10}, {last_block_row_length, 4'h0, block_height, block_width});
         write_to_reg({base,5'h14}, line_skip);
         write_to_reg({base,5'h00}, 0);
         write_to_reg({base,5'h00}, {offset, plane_transfers, 4'b10, mode_plane, mode_block, 2'b1});
      end
   endtask

   task ack_irq;
      input base;
      begin
         write_to_reg({base,5'h04}, 12'h20);
      end
   endtask

   // always begin
   //    repeat($urandom_range(4,1)) @(posedge clk);
   //    m_axis_mm2s_tready <= ~m_axis_mm2s_tready;
   // end
endmodule // top_tb
