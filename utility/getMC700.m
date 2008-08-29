function [mc700msg] = getMC700(conn)
mc700msg = '';
% if the amplifier is a MC 700a, this works and is very fast:
mc700msg  = fscanf(conn, '%s\n');
return;
% seems if it s a MC700B, we need to wait longer for a response:
tic;
while(conn.BytesAvailable == 0) % wait for response
    if(toc >= 1)% wait for one second for reply, but no longer
        fprintf(2, 'tcpip timed out!\n');
        return;
    end;
end;
 mc700msg = fscanf(conn, '%s', conn.BytesAvailable);
 return;
% now there is data, so get it!

while(conn.BytesAvailable > 0)
    tmp  = fread(conn, conn.BytesAvailable, 'char');
    mc700msg = [mc700msg; tmp']; %#ok<AGROW>
end;
