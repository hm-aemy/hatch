// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "register_interface/typedef.svh"
`include "obi/typedef.svh"

package user_pkg;

  ////////////////////////////////
  // User Manager Address maps //
  ///////////////////////////////
  
  // None


  /////////////////////////////////////
  // User Subordinate Address maps ////
  /////////////////////////////////////

  localparam int unsigned NumUserDomainSubordinates = 1;

  localparam bit [31:0] UserSpiAddrOffset   = 32'h4000_0000;
  localparam bit [31:0] UserSpiAddrRange    = 32'h2000_0000;          // reserve 512MB for external SPI SRAM

  localparam int unsigned NumUserSbrRules  = NumUserDomainSubordinates; // number of address rules in the decoder
  localparam int unsigned NumUserSbr       = NumUserSbrRules + 1; // additional OBI error, used for signal arrays

  // Enum for bus indices
  typedef enum int {
    UserError = 0,
    UserSpi   = 1
  } user_demux_outputs_e;

  // Address rules given to address decoder
  localparam croc_pkg::addr_map_rule_t [NumUserSbrRules-1:0] user_addr_map = '{
    '{ idx: UserSpi, start_addr: UserSpiAddrOffset, end_addr: UserSpiAddrOffset + UserSpiAddrRange}    // 1: SPI SRAM window
  };

endpackage
