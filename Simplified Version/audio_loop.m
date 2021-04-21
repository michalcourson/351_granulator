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


granL = Granulator(fs, frameLength, 4410);
granR = Granulator(fs, frameLength, 4410);
while ~t.XButton.Value
    if t.Plot
        plotbuffer(granL, t);
        t.Plot = false;
    end
    signal = fileReader();
    out_signal(:,1) = process(granL, signal, t);
    out_signal(:,2) = process(granR, signal, t);
    deviceWriter(out_signal);
    scope(out_signal);
end

release(fileReader)
release(deviceWriter)
release(scope)
all_fig = findall(0, 'type', 'figure');
close(all_fig)


