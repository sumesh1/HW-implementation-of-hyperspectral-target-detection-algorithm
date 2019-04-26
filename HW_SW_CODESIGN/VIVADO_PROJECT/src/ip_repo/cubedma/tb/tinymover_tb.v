`timescale 1ns/1ps

module tinymover_tb;
   parameter PERIOD = 10;

   reg clk, aresetn;

   reg [3:0] m_axi_mm2s_arid;
   wire [31:0] m_axi_mm2s_araddr;
   wire [7:0] m_axi_mm2s_arlen;
   wire [2:0] m_axi_mm2s_arsize;
   wire [1:0] m_axi_mm2s_arburst;
   wire m_axi_mm2s_arvalid;
   wire m_axi_mm2s_arready;
   wire [63:0] m_axi_mm2s_rdata;
   wire [1:0] m_axi_mm2s_rresp;
   wire m_axi_mm2s_rlast;
   wire m_axi_mm2s_rvalid;
   wire m_axi_mm2s_rready;
   wire [3:0] m_axi_mm2s_rid;

   wire [63:0] m_axis_mm2s_tdata;
   wire m_axis_mm2s_tlast;
   wire m_axis_mm2s_tvalid;
   reg m_axis_mm2s_tready;

   reg [40:0] cmd_tdata;
   reg        cmd_tvalid;
   wire       cmd_tready;

   // Block RAM for DataMover to read from.
   // The Block RAM is given initial data through a COE file.
   blk_mem_tinymover_tb i_bram
     (
      .s_aclk(clk),                // input wire s_aclk
      .s_aresetn(aresetn),          // input wire s_aresetn

      .s_axi_arid(m_axi_mm2s_arid),        // input wire [3 : 0] s_axi_arid
      .s_axi_araddr(m_axi_mm2s_araddr),    // input wire [31 : 0] s_axi_araddr
      .s_axi_arlen(m_axi_mm2s_arlen),      // input wire [7 : 0] s_axi_arlen
      .s_axi_arsize(m_axi_mm2s_arsize),    // input wire [2 : 0] s_axi_arsize
      .s_axi_arburst(m_axi_mm2s_arburst),  // input wire [1 : 0] s_axi_arburst
      .s_axi_arvalid(m_axi_mm2s_arvalid),  // input wire s_axi_arvalid
      .s_axi_arready(m_axi_mm2s_arready),  // output wire s_axi_arready
      .s_axi_rid(m_axi_mm2s_rid),          // output wire [3 : 0] s_axi_rid
      .s_axi_rdata(m_axi_mm2s_rdata),      // output wire [63 : 0] s_axi_rdata
      .s_axi_rresp(m_axi_mm2s_rresp),      // output wire [1 : 0] s_axi_rresp
      .s_axi_rlast(m_axi_mm2s_rlast),      // output wire s_axi_rlast
      .s_axi_rvalid(m_axi_mm2s_rvalid),    // output wire s_axi_rvalid
      .s_axi_rready(m_axi_mm2s_rready)    // input wire s_axi_rready
      );

   tinymover
     i_dut (
      .clk(clk),
      .aresetn(aresetn),

            .cmd_tdata(cmd_tdata),
            .cmd_tready(cmd_tready),
            .cmd_tvalid(cmd_tvalid),

      .m_axi_araddr(m_axi_mm2s_araddr),
      .m_axi_arlen(m_axi_mm2s_arlen),
      .m_axi_arsize(m_axi_mm2s_arsize),
      .m_axi_arburst(m_axi_mm2s_arburst),
      .m_axi_arvalid(m_axi_mm2s_arvalid),
      .m_axi_arready(m_axi_mm2s_arready),
      .m_axi_rdata(m_axi_mm2s_rdata),
      .m_axi_rresp(m_axi_mm2s_rresp),
      .m_axi_rlast(m_axi_mm2s_rlast),
      .m_axi_rvalid(m_axi_mm2s_rvalid),
      .m_axi_rready(m_axi_mm2s_rready),

      .m_axis_tdata(m_axis_mm2s_tdata),
      .m_axis_tlast(m_axis_mm2s_tlast),
      .m_axis_tvalid(m_axis_mm2s_tvalid),
      .m_axis_tready(m_axis_mm2s_tready)
            );

   always #(PERIOD/2) clk = ~clk;

   initial begin
      clk <= 1'b1;
      aresetn <= 1'b1;
      repeat(2) @(posedge clk);
      aresetn <= 1'b0;

      m_axi_mm2s_arid <= 4'b0;
      m_axis_mm2s_tready <= 1'b1;

      repeat(4) @(posedge clk);
      aresetn <= 1'b1;

      repeat(2) @(posedge clk);

      issue_cmd(32'h00100001, 2, 1);
      issue_cmd(32'h00100007, 1, 0);
      // issue_cmd(32'h00100000, 6);
      // issue_cmd(32'h00100007, 5);
   //   issue_cmd(32'h00100013, 87);
      issue_cmd(32'h00100ff1, 12, 1);
//      issue_cmd(32'h00100007, 5, 0);
      cmd_tvalid <= 1'b0;
   end // initial begin

   task issue_cmd;
      input [31:0] address;
      input [7:0] length;
      input       tag;
      begin
         cmd_tvalid <= 1'b0;
         while (cmd_tready != 1'b1) begin
            @(posedge clk);
         end

         cmd_tdata <= {tag, length, address};
         cmd_tvalid <= 1'b1;
         @(posedge clk);
      end
   endtask
endmodule // top_tb
