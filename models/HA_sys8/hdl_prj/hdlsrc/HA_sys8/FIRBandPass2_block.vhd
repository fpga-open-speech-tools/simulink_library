-- ------------------------------------------------------------
-- 
-- File Name: hdl_prj\hdlsrc\HA_sys8\FIRBandPass2_block
-- Created: 2018-12-04 11:17:49
-- Generated by MATLAB 9.4 and HDL Coder 3.12
-- 
-- ------------------------------------------------------------
-- 
-- 
-- ------------------------------------------------------------
-- 
-- Module: FIRBandPass2_block
-- Source Path: /FIRBandPass2_block
-- 
-- ------------------------------------------------------------
-- 
-- HDL Implementation    : Partly Serial
-- Folding Factor        : 8
-- Multipliers           : 2


LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.ALL;

ENTITY FIRBandPass2_block IS
   PORT( clk                             :   IN    std_logic; 
         enb_8_16_1                      :   IN    std_logic; 
         reset                           :   IN    std_logic; 
         FIRBandPass2_block_in           :   IN    std_logic_vector(31 DOWNTO 0); -- sfix32_En28
         FIRBandPass2_block_out          :   OUT   std_logic_vector(31 DOWNTO 0)  -- sfix32_En28
         );

END FIRBandPass2_block;


----------------------------------------------------------------
--Module Architecture: FIRBandPass2_block
----------------------------------------------------------------
ARCHITECTURE rtl OF FIRBandPass2_block IS
  -- Local Functions
  -- Type Definitions
  TYPE delay_pipeline_type IS ARRAY (NATURAL range <>) OF signed(31 DOWNTO 0); -- sfix32_En28
  -- Constants
  CONSTANT coeff1                         : signed(31 DOWNTO 0) := to_signed(11793810, 32); -- sfix32_En32
  CONSTANT coeff2                         : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff3                         : signed(31 DOWNTO 0) := to_signed(-19378142, 32); -- sfix32_En32
  CONSTANT coeff4                         : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff5                         : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff6                         : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff7                         : signed(31 DOWNTO 0) := to_signed(85850827, 32); -- sfix32_En32
  CONSTANT coeff8                         : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff9                         : signed(31 DOWNTO 0) := to_signed(-159216434, 32); -- sfix32_En32
  CONSTANT coeff10                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff11                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff12                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff13                        : signed(31 DOWNTO 0) := to_signed(510240978, 32); -- sfix32_En32
  CONSTANT coeff14                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff15                        : signed(31 DOWNTO 0) := to_signed(-1138084480, 32); -- sfix32_En32
  CONSTANT coeff16                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff17                        : signed(31 DOWNTO 0) := to_signed(1426107000, 32); -- sfix32_En32
  CONSTANT coeff18                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff19                        : signed(31 DOWNTO 0) := to_signed(-1138084480, 32); -- sfix32_En32
  CONSTANT coeff20                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff21                        : signed(31 DOWNTO 0) := to_signed(510240978, 32); -- sfix32_En32
  CONSTANT coeff22                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff23                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff24                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff25                        : signed(31 DOWNTO 0) := to_signed(-159216434, 32); -- sfix32_En32
  CONSTANT coeff26                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff27                        : signed(31 DOWNTO 0) := to_signed(85850827, 32); -- sfix32_En32
  CONSTANT coeff28                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff29                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff30                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff31                        : signed(31 DOWNTO 0) := to_signed(-19378142, 32); -- sfix32_En32
  CONSTANT coeff32                        : signed(31 DOWNTO 0) := to_signed(0, 32); -- sfix32_En32
  CONSTANT coeff33                        : signed(31 DOWNTO 0) := to_signed(11793810, 32); -- sfix32_En32

  -- Signals
  SIGNAL cur_count                        : unsigned(2 DOWNTO 0); -- ufix3
  SIGNAL phase_0                          : std_logic; -- boolean
  SIGNAL phase_1                          : std_logic; -- boolean
  SIGNAL delay_pipeline                   : delay_pipeline_type(0 TO 32); -- sfix32_En28
  SIGNAL FIRBandPass2_block_in_regtype    : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL inputmux_1                       : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL inputmux_2                       : signed(31 DOWNTO 0); -- sfix32_En28
  SIGNAL acc_final                        : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL acc_out_1                        : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL product_1                        : signed(62 DOWNTO 0); -- sfix63_En60
  SIGNAL product_1_mux                    : signed(31 DOWNTO 0); -- sfix32_En32
  SIGNAL mul_temp                         : signed(63 DOWNTO 0); -- sfix64_En60
  SIGNAL prod_typeconvert_1               : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL acc_sum_1                        : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL acc_in_1                         : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_cast                         : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_cast_1                       : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_temp                         : signed(65 DOWNTO 0); -- sfix66_En60
  SIGNAL acc_out_2                        : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL product_2                        : signed(62 DOWNTO 0); -- sfix63_En60
  SIGNAL product_2_mux                    : signed(31 DOWNTO 0); -- sfix32_En32
  SIGNAL mul_temp_1                       : signed(63 DOWNTO 0); -- sfix64_En60
  SIGNAL prod_typeconvert_2               : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL acc_sum_2                        : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL acc_in_2                         : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_cast_2                       : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_cast_3                       : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_temp_1                       : signed(65 DOWNTO 0); -- sfix66_En60
  SIGNAL sum1                             : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_cast_4                       : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_cast_5                       : signed(64 DOWNTO 0); -- sfix65_En60
  SIGNAL add_temp_2                       : signed(65 DOWNTO 0); -- sfix66_En60
  SIGNAL output_typeconvert               : signed(31 DOWNTO 0); -- sfix32_En28


BEGIN

  -- Block Statements
  Counter_process : PROCESS (clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF reset = '1' THEN
        cur_count <= to_unsigned(0, 3);
      ELSIF enb_8_16_1 = '1' THEN
        IF cur_count >= to_unsigned(7, 3) THEN
          cur_count <= to_unsigned(0, 3);
        ELSE
          cur_count <= cur_count + to_unsigned(1, 3);
        END IF;
      END IF;
    END IF; 
  END PROCESS Counter_process;

  phase_0 <= '1' WHEN cur_count = to_unsigned(0, 3) AND enb_8_16_1 = '1' ELSE '0';

  phase_1 <= '1' WHEN  (((cur_count = to_unsigned(0, 3))  OR
                         (cur_count = to_unsigned(1, 3))  OR
                         (cur_count = to_unsigned(2, 3))  OR
                         (cur_count = to_unsigned(3, 3))  OR
                         (cur_count = to_unsigned(4, 3)))  AND enb_8_16_1 = '1') ELSE '0';

  Delay_Pipeline_process : PROCESS (clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF reset = '1' THEN
        delay_pipeline(0 TO 32) <= (OTHERS => (OTHERS => '0'));
      ELSIF phase_0 = '1' THEN
        delay_pipeline(0) <= signed(FIRBandPass2_block_in);
        delay_pipeline(1 TO 32) <= delay_pipeline(0 TO 31);
      END IF;
    END IF; 
  END PROCESS Delay_Pipeline_process;

  FIRBandPass2_block_in_regtype <= signed(FIRBandPass2_block_in);

  inputmux_1 <= FIRBandPass2_block_in_regtype WHEN ( cur_count = to_unsigned(0, 3) ) ELSE
                     delay_pipeline(2) WHEN ( cur_count = to_unsigned(1, 3) ) ELSE
                     delay_pipeline(6) WHEN ( cur_count = to_unsigned(2, 3) ) ELSE
                     delay_pipeline(8) WHEN ( cur_count = to_unsigned(3, 3) ) ELSE
                     delay_pipeline(12) WHEN ( cur_count = to_unsigned(4, 3) ) ELSE
                     delay_pipeline(14) WHEN ( cur_count = to_unsigned(5, 3) ) ELSE
                     delay_pipeline(16) WHEN ( cur_count = to_unsigned(6, 3) ) ELSE
                     delay_pipeline(18);

  inputmux_2 <= delay_pipeline(19) WHEN ( cur_count = to_unsigned(0, 3) ) ELSE
                     delay_pipeline(24) WHEN ( cur_count = to_unsigned(1, 3) ) ELSE
                     delay_pipeline(26) WHEN ( cur_count = to_unsigned(2, 3) ) ELSE
                     delay_pipeline(30) WHEN ( cur_count = to_unsigned(3, 3) ) ELSE
                     delay_pipeline(32);

  --   ------------------ Serial partition # 1 ------------------

  product_1_mux <= coeff1 WHEN ( cur_count = to_unsigned(0, 3) ) ELSE
                        coeff3 WHEN ( cur_count = to_unsigned(1, 3) ) ELSE
                        coeff7 WHEN ( cur_count = to_unsigned(2, 3) ) ELSE
                        coeff9 WHEN ( cur_count = to_unsigned(3, 3) ) ELSE
                        coeff13 WHEN ( cur_count = to_unsigned(4, 3) ) ELSE
                        coeff15 WHEN ( cur_count = to_unsigned(5, 3) ) ELSE
                        coeff17 WHEN ( cur_count = to_unsigned(6, 3) ) ELSE
                        coeff19;
  mul_temp <= inputmux_1 * product_1_mux;
  product_1 <= mul_temp(62 DOWNTO 0);

  prod_typeconvert_1 <= resize(product_1, 65);

  add_cast <= prod_typeconvert_1;
  add_cast_1 <= acc_out_1;
  add_temp <= resize(add_cast, 66) + resize(add_cast_1, 66);
  acc_sum_1 <= add_temp(64 DOWNTO 0);

  acc_in_1 <= prod_typeconvert_1 WHEN ( phase_0 = '1' ) ELSE
                   acc_sum_1;

  Acc_reg_1_process : PROCESS (clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF reset = '1' THEN
        acc_out_1 <= (OTHERS => '0');
      ELSIF enb_8_16_1 = '1' THEN
        acc_out_1 <= acc_in_1;
      END IF;
    END IF; 
  END PROCESS Acc_reg_1_process;

  --   ------------------ Serial partition # 2 ------------------

  product_2_mux <= coeff21 WHEN ( cur_count = to_unsigned(0, 3) ) ELSE
                        coeff25 WHEN ( cur_count = to_unsigned(1, 3) ) ELSE
                        coeff27 WHEN ( cur_count = to_unsigned(2, 3) ) ELSE
                        coeff31 WHEN ( cur_count = to_unsigned(3, 3) ) ELSE
                        coeff33;
  mul_temp_1 <= inputmux_2 * product_2_mux;
  product_2 <= mul_temp_1(62 DOWNTO 0);

  prod_typeconvert_2 <= resize(product_2, 65);

  add_cast_2 <= prod_typeconvert_2;
  add_cast_3 <= acc_out_2;
  add_temp_1 <= resize(add_cast_2, 66) + resize(add_cast_3, 66);
  acc_sum_2 <= add_temp_1(64 DOWNTO 0);

  acc_in_2 <= prod_typeconvert_2 WHEN ( phase_0 = '1' ) ELSE
                   acc_sum_2;

  Acc_reg_2_process : PROCESS (clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF reset = '1' THEN
        acc_out_2 <= (OTHERS => '0');
      ELSIF phase_1 = '1' THEN
        acc_out_2 <= acc_in_2;
      END IF;
    END IF; 
  END PROCESS Acc_reg_2_process;

  add_cast_4 <= acc_out_2;
  add_cast_5 <= acc_out_1;
  add_temp_2 <= resize(add_cast_4, 66) + resize(add_cast_5, 66);
  sum1 <= add_temp_2(64 DOWNTO 0);

  Finalsum_reg_process : PROCESS (clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF reset = '1' THEN
        acc_final <= (OTHERS => '0');
      ELSIF phase_0 = '1' THEN
        acc_final <= sum1;
      END IF;
    END IF; 
  END PROCESS Finalsum_reg_process;

  output_typeconvert <= (31 => '0', OTHERS => '1') WHEN acc_final(64) = '0' AND acc_final(63) /= '0'
      ELSE (31 => '1', OTHERS => '0') WHEN acc_final(64) = '1' AND acc_final(63) /= '1'
      ELSE (acc_final(63 DOWNTO 32));

  -- Assignment Statements
  FIRBandPass2_block_out <= std_logic_vector(output_typeconvert);
END rtl;
