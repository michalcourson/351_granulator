classdef Granulator < handle
    %GRANULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        buffer
        frame_size
        grain_size
        grain_buffer
        grain_index
        sample_rate
    end
    
    methods
        function obj = Granulator(in_sample_rate,in_frame_size, in_grain_size)
            %GRANULATOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.sample_rate = in_sample_rate;
            obj.buffer = zeros(in_sample_rate*5, 1);
            obj.frame_size = in_frame_size;
            obj.grain_index = 1;
            obj.grain_buffer = zeros(in_grain_size, 1);
            obj.grain_size = in_grain_size;
        end
        
        function out_frame = process(obj, in_frame, t)
            in_grain_size = floor(obj.sample_rate * t.GrainSizemsKnob.Value / 1000);
            in_spread = floor(obj.sample_rate * t.SpreadmsKnob.Value / 1000) + 1;
            in_pos = floor(obj.sample_rate * t.PosmsKnob.Value / 1000);
            reverse = randi(100) < t.ReverseKnob.Value;
            if ~t.FreezeButton.Value
                obj.buffer = circshift(obj.buffer, -obj.frame_size);
                obj.buffer(end-obj.frame_size+1:end) = in_frame;
            end
            out_frame = zeros(obj.frame_size,1);
            for samp = 1:obj.frame_size
                if obj.grain_index > obj.grain_size/2
                    obj.grain_buffer = circshift(obj.grain_buffer, -floor(obj.grain_size/2));
                    if obj.grain_size < in_grain_size
                        tmp = zeros(in_grain_size,1);
                        tmp(1:obj.grain_size) = obj.grain_buffer;
                        obj.grain_size = in_grain_size;
                        obj.grain_buffer = tmp;
                    end
                    if obj.grain_size > in_grain_size
                        obj.grain_size = in_grain_size;
                        obj.grain_buffer = obj.grain_buffer(1:obj.grain_size);
                    end
                    if t.FreezeButton.Value
                        grain_start = in_pos + randi(in_spread) - floor(in_spread/2);
                        grain_start = max([grain_start, 1]);
                        grain_start = min([grain_start, length(obj.buffer) - obj.grain_size - 1]);
                    else
                        grain_start = length(obj.buffer) - obj.frame_size + samp - obj.grain_size - 1 - randi(in_spread);
                    end
                    grain_end = grain_start + obj.grain_size - 1;
                    obj.grain_buffer(floor(obj.grain_size/2)+1:end) = zeros(ceil(obj.grain_size/2),1);
                    if reverse
                        obj.grain_buffer = obj.grain_buffer + hann(obj.grain_size).*flip(obj.buffer(grain_start:grain_end));
                    else
                        obj.grain_buffer = obj.grain_buffer + hann(obj.grain_size).*obj.buffer(grain_start:grain_end);
                    end
                    obj.grain_index = 1;
                end
                out_frame(samp) = obj.grain_buffer(obj.grain_index);
                obj.grain_index = obj.grain_index+1;
            end
        end
        
        function plotbuffer(obj, t)
            plot(t.UIAxes, obj.buffer);
            xline(t.UIAxes, floor(obj.sample_rate * t.PosmsKnob.Value / 1000), '-r');
            xline(t.UIAxes, floor(obj.sample_rate * t.PosmsKnob.Value / 1000) - floor(obj.sample_rate * t.SpreadmsKnob.Value / 2000), '--r');
            xline(t.UIAxes, floor(obj.sample_rate * t.PosmsKnob.Value / 1000) + floor(obj.sample_rate * t.SpreadmsKnob.Value / 2000), '--r');
        end
    end
end

