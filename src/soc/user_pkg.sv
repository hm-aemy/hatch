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

  localparam bit [31:0] UserRamAddrOffset   = croc_pkg::UserBaseAddr; // 32'h2000_0000;
  localparam bit [31:0] UserRamAddrRange    = 32'h0000_4000;          // every subordinate has at least 4KB

  localparam int unsigned NumUserSbrRules  = NumUserDomainSubordinates; // number of address rules in the decoder
  localparam int unsigned NumUserSbr       = NumUserSbrRules + 1; // additional OBI error, used for signal arrays

  // Enum for bus indices
  typedef enum int {
    UserError = 0,
    UserRam   = 1
  } user_demux_outputs_e;

  // Address rules given to address decoder
  localparam croc_pkg::addr_map_rule_t [NumUserSbrRules-1:0] user_addr_map = '{
    '{ idx: UserRam, start_addr: UserRamAddrOffset, end_addr: UserRamAddrOffset + UserRamAddrRange}   // 1: User RAM
  };

endpackage
