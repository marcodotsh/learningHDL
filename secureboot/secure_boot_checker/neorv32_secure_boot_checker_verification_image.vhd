-- The NEORV32 RISC-V Processor - github.com/stnolting/neorv32
-- Auto-generated RSA public key initialization image (for secure boot checker)
-- Built: 24.07.2025 12:39:16

library ieee;
use ieee.std_logic_1164.all;

use work.neorv32_package.all;

package neorv32_secure_boot_checker_verification_image is

  constant rsa_modulus_c : std_ulogic_vector(511 downto 0) := x"AF3ACDB97693254D84FA56D537F657CDD080BF0A0C7783A0701CD0ED932FE8EA9C5C6481A60F10426F2D5F44BBD03CE8FFA946A7171B659BBD54DB2E2BC2491B";
  constant rsa_public_exponent_c : std_ulogic_vector(19 downto 0) := x"10001";
end neorv32_secure_boot_checker_verification_image;
