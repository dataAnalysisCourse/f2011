function [spikes] = threshold(theta,ini,tau,mp)
N = length(mp);
T = ceil(tau*log(1e-6)*1000);
filter = -ini*exp((0:0.001:(T-1)/1000)/tau);
r = zeros(1,N);
spikes = r;
c = r+mp;

for k=1:N

    if(c(k)>=theta)
        spikes(k)=1;
        r(k:min(k+T-1,N)) = r(k:min(k+T-1,N))+filter(1:min(T,N-k+1));
        c(k:min(k+T-1,N)) = r(k:min(k+T-1,N))+mp(k:min(k+T-1,N));
    end
    
end



end