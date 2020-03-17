
# FPGA Open Speech Tools -- DSP FPGA Accelerated Toolbox
Copyright 2020 Flat Earth Inc

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 Ross K. Snider
 Justin P. Williams
 E. Bailey Galacci
 Flat Earth Inc
 985 Technology Blvd
 Bozeman, MT 59718
 support@flatearthinc.com

This README is focused on explaining how to use each of the blocks provided within this library.
There will also be detailed explanation on the design of each block.

The DSP FPGA Accelerated Toolbox is designed as a hardware friendly support to the existing hdllib library. 

## Table of Contents
1. Programmable Look-Up Table
2. Programmable Look-Up Table, Linear Scale
3. Static Upclocked FIR 
4. Programmable Upclocked FIR 
5. Circular Buffer, Variable Delay 

## Programmable Look-Up Table (PLUT)
A log-scale lookup table, designed to emulate transcendental functions with minimal resource usage.  
Accuracy is boosted through the use of linear interpolation, without the use of division.  On initialization, the PLUT represents a single user-defined function with input "xIn". xIn does not need to be defined in the workspace,  as it will be defined in the initialization script of the block in the local workspace. The PLUT adjusts its own size to fit the user-defined accuracy. Note points are pseudo-logarithmically spaced to increase precision throughout the input space.

Tables can be initialized on system startup and rewritten during runtime using the Table_Wr lines.
Min input cannot be 0, because inputs are pseudo-logarithmically spaced.

Input and Output set can be saved as "xIn" and "tableInit" within the file "<path name> init.mat" for ease of reprogramming. Input values remain constant until the mask parameters are updated. Table Output values can be reprogrammed during runtime using the Wr_Data, Wr_En and RW_Addr lines.

Uses pseudo-logarithmic spacing of inputs for maximum accuracy in non-linear functions, as well as linear interpolation between points to further increase accuracy. Because of this, it is assumed that function input is unsigned. If this is undesired, a second table would need to be implemented to cover negative values, or some other solution outside the block.

Capable of automatically determining required table size to meet a given accuracy requirement within the entire data range, or can be manually set to a specific size with M_bits and N_bits. N_bits determines the data range as a power of 1/2 of the maximum input. M_bits determines the number of bits in the address used to increase function precision, by increasing the number of points stored between each log2 spaced input point.

### Mask Parameters 
This section goes over a detailed description of the mask parameters when configuring the PLUT block. 

- Table Represented Function:
Function to estimate using the lookup table. Must contain the variable "X_in" as an input to a function, or as a variable within the executable code string, as this is used in the Initialization code to evaluate the function. If a function, that function must also have a single output which will define the values to fill the table with given input value X_in.

- Save Table Input/Output set as .mat
If asserted, the table's inputs and outputs will be saved in a .mat file named "<path name>_init.mat". By loading this, it is possible to see all precalculated points of the look-up table. This is especially useful when trying to reprogram the table, as all input points are shown along with their associated addresses.

#### Table Parameters
- Maximum Input Value
  The maximum input value the table should be expected to represent. If the input value is greater than this parameter's nearest higher power of 2, the table will output the value for the highest input.

#### Define Input Threshold and Accuracy Tab
- Minimum Input Threshold: 
The minimum input to recognize by the table. If the input value is less than this parameter's the nearest lower power of 2, the table will output the value for the lowest input.

- Maximum Allowed Error (%)
The amount of percent error allowed by the table. Used by the init script to identify the size of the table required to meet this parameter. This is found by testing a set of examples 4 times larger than the table set, therefore it is possible on rare occasion for some points to exceed this error. Decreasing this will increase the memory required for the table, but increase precision. 

- Show Error Calculation
When asserted, the block will pop-up graphs showing the error calculation and a pop-up detailing the amount of memory used, size of the RAM allocated, and maximum error.

- Show Table Init Plot:
   When asserted, the block will show a figure of the table's initialized values.
	
#### Define Address Space Manually Tab
 - N_bits: Only used when Manual Bit Definition Override is asserted.
    The width of the address dedicated to breadth of valid data. Increasing this will cause the table to recognize smaller numbers (by increasing the size of the Leading Zero Counter's output)  at the cost of memory used, and more logic required in the LZC. 
 - M_bits: Only used when Manual Bit Definition Override is asserted. The width of the address dedicated to depth of valid data. Increasing this will cause more bits of the input to be considered as part of the address after the Leading Zero Counter, increasing precision at the cost of memory.

#### Manual Bit Definition Override
Checking this box will skip automatic size definition of Leading Zero Counter and precision bit size. Use with caution, as percent error will not be guaranteed with this setting on. Read the formal documentation for more details, kept within the file structure this library is stored in.

#### Data Parameters dropdown

 - Word Bits: Size of fixed point word of both the input signal and table memory.

 - Fractional Bits:  Number of fractional bits in the fixed point word of both the input signal and table memory.


### Block I/O
This section describes the inputs and outputs of the PLUT mask to be used in a Simulink model.
#### Inputs: 

- Data_In
  Input signal to be looked-up. Expected size fixdt(0,Word Bits, Fractional Bits).

- Table_Wr_Data % Table Write Data
Data to write to the table, in location Table_RW_Addr, when Table_Wr_En is asserted. Expected size fixdt(0,Word Bits, Fractional Bits).

- Table_RW_Addr % Table Read/Write Address
The location within the table to read or overwrite. Expected size changes based on the function and allowed error as initialized, and is shown on the Mask Label as RAM Width, or by checking the "Show Error Calculation" button as RAM Width. 
  
There is an internal check that will correct a signal of the wrong size to the correct address size, but it may be useful to know the X values associated with table output at any given address. Using the "Save Table Input/Output as .mat" option will   save the entire set of initialized inputs and outputs along with their associated addresses.

For a full explanation on how xIn is derived, see the formal documentation contained within the file structure this library is stored in.

- Table_Wr_En % Table Write Enable
  Boolean. If this line is asserted, address Table_RW_Addr will be overwritten with data Table_Wr_Data. 


#### Outputs: 
- Data_Out
  Output data of the table. Size fixdt(1,Word Bits, Fractional Bits).

- Table_RW_Dout % Table Read/Write Data Out
  Outputs the data currently within address Table_RW_Addr (after writing if Table_Wr_En is asserted).


## Programmable Look-Up Table, Linear Scale
A hardware-oriented implementation of a lookup table. Provides a fairly resource efficient way to avoid hardware-difficult operations, such as logarithms or square roots. 

Tables can be initialized on system startup and rewritten during runtime using the Table_Wr lines. 

Capable of automatically determining required table size to meet a given accuracy requirement within the entire data range, or can be manually set to a specific size with N_bits. Data Range is determined by the word size and fractional bit size of data entering the PLUT.

### Mask Parameters 


*Table Represented Function:*
  Function to estimate using the lookup table. Must contain the variable "X_in" as an input to a function, or as a variable within the executable code string, as this is used in the Initialization code to evaluate the function. If a function, that function must also have a single output which will define the values to fill the table with given input value X_in.

Save Table Input/Output set as .mat
  If asserted, the table's inputs and outputs will be saved in a .mat file named "<path name>_init.mat". By loading this, it is possible to see all precalculated points of the look-up table. This is especially useful when trying to reprogram the table, as all input points are shown along with their associated addresses.

#### Table Parameters
  - Maximum Input Value: 
    The maximum input value the table should be expected to represent. This is based on the data range of the fixed point word size and fractional size, and adjusted if the data is signed.

#### Define Input Range and Accuracy Tab
  Maximum Allowed Error (+/-):
    The amount of absolute error allowed by the table. Used by the init script to identify the size of the table required to meet this parameter. This is found by testing a set of examples 4 times larger than the table set, therefore it is possible on rare occasion for some points to exceed this error. Decreasing this will increase the memory required for the table, but increase precision. 

  - Show Error Calculation:
    When asserted, the block will show a figure of the error calculation and a pop-up detailing the amount of memory used, size of the RAM allocated, and maximum error.

  - Show Table Init Plot: 
    When asserted, the block will show a figure of the table's initialized values.
 
- Define Address Space Manually Tab
  Address Width:
    Only used when Manual Bit Definition Override is asserted.
    The width of the address dedicated to depth of valid data.  Increasing this will cause more bits of the input to be considered as part of the address, increasing precision at the cost of memory.

- Manual Bit Definition Override:
    Checking this box will skip automatic size definition of precision bit size. Use with caution, as absolute error will not be guaranteed with this setting on. Read the formal documentation for more details, kept within the file structure this library is stored in.


#### Data Parameters dropdown
- Word Bits: 
  Size of fixed point word of both the input signal and table memory.

- Fractional Bits:
  Number of fractional bits in the fixed point word of both the input signal and table memory.

- Data Signed:
  Check if data is signed. Adjusts table's values and readout if data is signed.


### Block I/O

#### Inputs: 

- Data_In: 
   Input signal to be looked-up. Expected size fixdt(isSigned,Word Bits, Fractional Bits).

- Table_Wr_Data % Table Write Data:
  Data to write to the table, in location Table_RW_Addr, when Table_Wr_En is asserted. Expected size fixdt(isSigned,Word Bits, Fractional Bits).

- Table_RW_Addr % Table Read/Write Address:
  The location within the table to read or overwrite. Expected size changes based on the function and allowed error as initialized, and is shown on the Mask Label as RAM Width, or by checking the "Show Error Calculation" button as RAM Width. 
  
  There is an internal check that will correct a signal of the wrong size to the correct address size, but it may be useful to know the X values associated with table output at any given address. Using the "Save Table Input/Output as .mat" option will save the entire set of initialized inputs and outputs along with their associated addresses.
  
  For a full explanation on how xIn is derived, see the formal documentation contained within the file structure this library is stored in.

- Table_Wr_En % Table Write Enable:
  Boolean. If this line is asserted, address Table_RW_Addr will be overwritten with data Table_Wr_Data. 


#### Outputs: 
- Data_Out:
  Output data of the table. Size fixdt(isSigned,Word Bits, Fractional Bits).

- Table_RW_Dout % Table Read/Write Data Out:
  Outputs the data currently within address Table_RW_Addr (after writing if Table_Wr_En is asserted). Size fixdt(isSigned, Word Bits, Fractional Bits).

## Static Upclocked FIR 
This block is designed for a hardware implementation of an FIR filter. The main advantage is resource sharing by using a single multiply/add at an increased clock rate to multiply the b_k coefficients and sum the results.

The cost is a slightly increased amount of RAM used and the requirement that the system can run at data_rate*b_k_length, where b_k_length is rounded up to the nearest power of 2. The gains over a traditional FIR are a vastly decreased latency and logic resource usage.

An "Added Delay" option is included as a way to save resources when delaying the filtered signal. The b_k RAM is padded with zeros to round length up to a power of 2. Therefore, many faster cycles are completely unnecessary. Since many b_k's are 0, they can be rotated to align with inputs starting before the most recent, effectively delaying the output signal with 0 extra resources used. Useful for things like realigning a signal after multi-channel processing, or any other reason to delay the signal. If Added Delay would cause rotation to read from undesired coefficients (not 0), on startup the system will automatically increase the size of the table. This doubles the RAM used, so if using a b_k length at or near a power of 2, or if a very long delay is required, this may not be the most efficient option.

B_k's are defined on system start-up and *cannot be changed during runtime*.

### Mask Parameters
Configurable mask parameters:
- B_k coefficients:
  FIR filter coefficients
- Sample Time:
  Amount of time between valid pulses, when the input signal needs to be recognized.
- System Time:
  Amount of time between system clock cycles. Can be the same as Sample Time if Valid_in is always 1.
- Added Delay:
  Adds a N-sample delay to the output. Check Documentation Description for details.
- Fixed Point Word/Frac Size:
  Word and Fractional bit size of input and table data type. Data input and b_k's are assumed to be the same data type.

### Block I/O
Signal routing block IO descriptions:
- Data_in: 
  Input signal to be processed. Can be of any rate a direct multiple of "Sample rate". Signed Fixed Point of size "Fixed Point Word Size".
- Valid_in: 
 Trigger to show input signal should be written to signal memory of FIR RAM. Active high. Boolean.

- Data_out:
  Output signal after processing. Set to sample time "System Time". Signed Fixed Point of size "Fixed
Point Word Size". Zero-order hold.
- Valid_out: 
  Signal identifying when the output is a new processed value. Active high. Boolean.


## Programmable Upclocked FIR 
A Programmable Upclocked FIR (PFIR) designed to filter signals within an FPGA hardware accelerated system with the function of programming new filter coefficient sets during runtime. The coefficient sets are stored in RAM and are accessed within a single clock cycle post programming. 

An "Added Delay" option is included as a way to save resources when delaying the filtered signal. The b_k RAM is padded with 0s to round length up to a power of 2. Therefore, many faster cycles are completely uneccessary. Since many b_k's are 0, they can be rotated to align with inputs starting before the most recent, effectively delaying the output signal with 0 extra resources used. Useful for things such as realigning a signal after multi-channel processing. If Added Delay would cause rotation to read from undesired coefficients (not 0), on startup, the system will automatically increase the size of the table. This doubles the RAM used, so if using a b_k length at or near a power of 2, or if a very long delay is required, this may not be the most efficient option.


B_k's are defined on system start-up and can be changed during runtime through the Wr_Data, Wr_Addr, and Wr_En signals.
B_k's can be ready using the Wr_Addr, Wr_En set to 0, sent out to the RW_Dout line.

### Mask Parameters 
Defined mask parameters for a user to configure when using the PFIR library block within a Simulink model.

- B_k coefficients:
  FIR filter coefficients. Recommended to use filter sizes by powers of 2. 
- Sample Time:
  Amount of time between valid pulses, when the input signal needs to be recognized.
- System Time:
  Amount of time between system clock cycles. Can be the same as Sample Time if Valid_in is always 1.
- Added Delay:
  Adds a N-sample delay to the output. Check Documentation Description for details.
- Fixed Point Word/Frac Size:
  Word and Fractional bit size of input and table data type. Data input and b_k's are assumed to be the same data type.

### Block I/O
This section allows the user to drive the Simulink library blocks with input source signals and route the output signals. 
#### Inputs
Block input descriptions below. 
- Data_in:
  Input signal to be processed. Can be of any rate a direct multiple of "Sample rate". Signed Fixed Point of size "Fixed Point Word Size".
- Valid_in:
 Trigger to show input signal should be written to signal memory of FIR RAM. Active high. Boolean.
- Wr_Data:
  Data to write to B_k at address Wr_Addr if Wr_En is set to 1. Data type overwritten to match input signal type.
- Wr_Addr:
  Location in table to write or read B_k table. Starts at 0 and ends at 2^N, where N is ceil(log2(length(B_k+Added_Delay)));
- Wr_En:
  Used to set behavior to read or write from b_k memory.
  Write: 1, Read: 0

#### Outputs
Block output descriptions below. 

- Data_out:
  Output signal after processing. Set to sample time "System Time". Signed Fixed Point of size "Fixed Point Word Size". Zero-order hold.
- Valid_out:
  Signal identifying when the output is a new processed value. Active high. Boolean.
- RW_Dout:
  Returns the value stored in Wr_Addr, after a 1 System clock cycle delay.
## Circular Buffer, Variable Delay 

