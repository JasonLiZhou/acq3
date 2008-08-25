function e(arg)
% e: edit parameters
% ***CMD***
% The line above specifies this file as avaialable at the command line in
% acq3

% Usage
%     use 'e a' for acquisition
%     use 'e s' for stimulus (main)
%	  use 'e 2' for secondary stimulus (parameter adjustment.....)
%     use 'e c' for configuration

% function to bring up different parameter views for editing
% 
global DFILE STIM STIM2 CONFIG

ecmds = {'acq', 'stim', '2nd', 'config'};
cmd = strmatch(lower(arg), ecmds);
if(isempty(cmd))
   QueMessage(sprintf('e: unrecognized parameter block %s', arg), 1);
   return;
end;

switch(cmd)
case 1
   struct_edit('edit', DFILE);
   
case 2
   struct_edit('edit', STIM);
   
case 3
   struct_edit('edit', STIM2);
   
case 4
   struct_edit('edit', CONFIG);
otherwise
end;
return;
