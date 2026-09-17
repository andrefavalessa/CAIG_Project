function truth = generateLevel2Sway(cfg)
%GENERATELEVEL2SWAY Generate the validated Zhang level-2 sway motion.
%
% Zhang supplies the amplitudes and periods. The sinusoidal time-domain
% waveform is an explicit project assumption. The 3-2-1 Euler-angle-rate
% to body-rate equations are unchanged from CAIG_Main_Simulation.m.

    truth.tFOG = ...
        (0:cfg.dtFOG:cfg.duration-cfg.dtFOG).';
    truth.tCAIG = ...
        (0:cfg.dtCAIG:cfg.duration-cfg.dtCAIG).';

    truth.NFOG = length(truth.tFOG);
    truth.NCAIG = length(truth.tCAIG);

    truth.timeFOG = seconds(truth.tFOG);
    truth.timeCAIG = seconds(truth.tCAIG);

    truth.OmegaFOG = level2SwayAtTimes(truth.tFOG,cfg);
    truth.OmegaCAIG = level2SwayAtTimes(truth.tCAIG,cfg);
end


function Omega = level2SwayAtTimes(t,cfg)

    wr = 2*pi/cfg.rollPeriod;
    wp = 2*pi/cfg.pitchPeriod;
    wh = 2*pi/cfg.headingPeriod;

    roll = cfg.rollAmp*sin(wr*t);
    pitch = cfg.pitchAmp*sin(wp*t);

    rollDot = cfg.rollAmp*wr*cos(wr*t);
    pitchDot = cfg.pitchAmp*wp*cos(wp*t);
    headingDot = cfg.headingAmp*wh*cos(wh*t);

    % 3-2-1 Euler-angle rates -> body rates
    p = rollDot-headingDot.*sin(pitch);
    q = pitchDot.*cos(roll)+headingDot.*sin(roll).*cos(pitch);
    r = -pitchDot.*sin(roll)+headingDot.*cos(roll).*cos(pitch);

    Omega = [p q r];
end
