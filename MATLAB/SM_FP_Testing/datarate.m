%determining throughput for SM implementation
%inputs: fps of imager, number of spectral bands
% ppf- pixels per frame, bpc- bits per component
% and divider latency

function [] = datarate (fps,bands,ppf,bpc,divider_latency)

if(nargin<5)
    divider_latency = 100;
end


fprintf("FPS is %d \n",fps);
fprintf("Bands  %d \n",bands);
fprintf("Pixels per frame is %d \n",ppf);
fprintf("Bits per component is %d \n",bpc);
fprintf("Divider latency is %d \n",divider_latency);


data_per_frame = ppf*bands*bpc/8/10^6; %in MB
fprintf("MegaBytes per frame is %f \n",data_per_frame);


data_rate = data_per_frame*fps; %in MB/s
fprintf("Incoming data rate is %f \n",data_rate);


cycles_per_pixel = 3*bands + 3 + divider_latency;
fprintf("CPP is %d \n",cycles_per_pixel);
f = 100*10^6; %100MHz operation frequency
T = 1/f;
t_per_pixel = T*cycles_per_pixel;
fpga_data_rate = bands*bpc/8/10^6/t_per_pixel;

fprintf("FPGA data processing rate is %f \n",fpga_data_rate);

end

