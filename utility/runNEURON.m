function [t, ic, v, err] = runNEURON (model, rdur, DT, waveform, ampmode)
%runNeuron is a skeleton script for running a model using NEURON from matlab
global BASEPATH
t=[];
ic=[];
v=[];
err = 0;
if(model >= 1 && model <= 6)
   FilePath = [BASEPATH 'model\vcn\'];
	hocFileName = 'acq_model.hoc';
   fprintf(1, 'Model - VCN');
end;
if(model == 7)
   FilePath = [BASEPATH 'model\dcn\'];
	hocFileName = 'acq_pyrmodel.hoc';
   fprintf(1, 'Model - DCN');
end;
FilePath = slash4OS(FilePath);
h = fopen([FilePath 'stim.dat'], 'w');
fprintf(h, '%d\n', model); % model selected
fprintf(h, '%d\n', ampmode); % type of acquisition (cc = 0, vc = 1)
fprintf(h, '%f\n', rdur); % duration of recording period (tstop)
fprintf(h, '%f\n', DT); % DT for vector to play
fprintf(h, '%d\n', length(waveform)); % number of points in istim
fprintf(h, '%f\n', waveform); % istim
fclose(h);

switch(computer)
    case 'PC'
        fullFileName = 'c:\nrn62\bin\nrniv.exe'; % where we expect to find NEURON

    case {'MAC', 'MACI'}
        fullFileName = '/Applications/NEURON-6.1/nrn/umac/bin/nrngui'; % or umac or i686, depdneing...        
end;
hocFile = [FilePath hocFileName];

a=pwd;
cd (FilePath);
cmd = ['! ' fullFileName ' ' hocFile  ];
eval(slash4OS(cmd));
cd(a);

% now read the file and plot the results.
if(~exist([FilePath 'testing.txt'], 'file'))
   return;
end;
h = fopen([FilePath 'testing.txt'], 'r');
model = fscanf(h, '%d',1); %#ok<NASGU>
sdt = fscanf(h, '%f', 1); %#ok<NASGU>
npts = fscanf(h, '%d', 1);
A = fscanf(h, '%g %g %g', [3 npts]);
fclose(h);
t = A(1,:)';
ic = 1000*A(2,:)';
v = A(3,:)';


