clear
close all;
frameLength = 512;
fs = 44100;
t = tutorialApp;
fileReader = audioDeviceReader('SampleRate',fs, ...
    'SamplesPerFrame', frameLength);
deviceWriter = audioDeviceWriter( ...
    'SampleRate',fileReader.SampleRate, ...
    'BufferSize', 4096);

scope = dsp.TimeScope( ...
    'SampleRate',fileReader.SampleRate, ...
    'TimeSpan', 2, ...
    'BufferLength',fileReader.SampleRate*2*2, ...
    'YLimits',[-1,1], ...
    'TimeSpanOverrunAction',"Scroll");

% Reverberator
reverb = reverberator('PreDelay',0.5,'WetDryMix',1.0, 'SampleRate', fs);

% Resonant Lowpass Filter
Q = 0.3;

f1 = t.CutoffFreqKnob.Value;
r = f1;
q = 1-f1*2*Q;
    
b0 = r*r;
a1 = r*r-q-1;
a2 = q;
    
% coefficients
zc = [b0];
pc = [1, a1, a2];

% poles and zeros
zr = roots(zc);
pr = roots(pc);


granL = Granulator(fs, frameLength, 4410);
granR = Granulator(fs, frameLength, 4410);
last_output = zeros(frameLength,2);
last_input = zeros(frameLength,2);

while ~t.XButton.Value
    if t.Plot
        plotbuffer(granL, t);
        t.Plot = false;
    end
    
    verbMix = t.ReverbDryWetKnob.Value;
    
    % Recalculate filter coefficients when knob is moved
    if t.Calc_filter 
        Q = t.QKnob.Value;
        
        f1 = t.CutoffFreqKnob.Value;
        f1 = (10 .^ (f1) ./ 9) - .111;
        if f1 > .98
            f1 = .98;
        end
        r = f1;
        q = 1-f1*2*Q;

        b0 = r*r;
        a1 = r*r-q-1;
        a2 = q;

        % coefficients
        zc = [b0];
        pc = [1, a1, a2];

        % poles and zeros
        zr = roots(zc);
        pr = roots(pc);
    end
    
    signal = fileReader();
    out_signal(:,1) = process(granL, signal, t);
    out_signal(:,2) = process(granR, signal, t);
    z_L = filtic(zc,pc,flip(last_output(:,1)),flip(last_input(:,1)));
    z_R = filtic(zc,pc,flip(last_output(:,2)),flip(last_input(:,2)));
    last_input = out_signal;
    out_signal(:,1) = filter(zc, pc, out_signal(:,1), z_L ,1); 
    out_signal(:,2) = filter(zc, pc, out_signal(:,2), z_R ,1);
    last_output = out_signal;

    
    % Mono reverb - wet/dry mixing
    out_signal = out_signal*(sqrt(1-verbMix)) + reverb(out_signal)*(sqrt(verbMix));

    deviceWriter(out_signal);
    scope(out_signal);
end

release(fileReader)
release(deviceWriter)
release(scope)
all_fig = findall(0, 'type', 'figure');
close(all_fig)

