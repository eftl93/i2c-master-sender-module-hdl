# i2c-master-sender-module-hdl
module to create i2c controler  
Hello, this module is an i2c master controller sender  

It still needs to be tested and debugged.  

i_clk        <= input clock\
i_nrest      <= active low reset\
i_data_write <= byte to be transmitted (must be valid before pressing start and at least for a cycle afterwards).\
i_addr      <= address for the slave devices that you wish to talk\
i_start     <= will start the transmission sequence\
i_read_or_write <= bit that will decide to read or write (0=write, 1=read).(must be valid before pressing start and at least for a cycle afterwards).\
i_word_cnt  <= 3 bit input to decide how many bytes will it be sent.\
o_scl       <= serial clock out\
o_sda       <= serial data out\
o_data_read <= byte read from the slave\
o_finished  <= current byte was sent and acknoledge bit was received

# Pending things to work on
-module hasn't been simulated or tested yet\
-Currently the i_word_cnt is not functioning, it is hard wired to only send one word\
-o_finished still not asserting
