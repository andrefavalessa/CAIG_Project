clear;
clc;
close all;

%% ========================================================================
%  TEST - CAIG scale factor and dynamic range
%
%  Main model:
%  Zhang et al. (2019)
%
%  Rotation phase - Eq. (6):
%
%       phi_rot = -2 * keff . (Omega x v) * T^2
%
%  For the V1 geometry:
%
%       phi_single = Ksingle * Omega
%
%       Ksingle = 2 * keff * v * T^2
%
%
%  For the dual-interferometer differential phase:
%
%       phi_diff = Kdual * Omega
%
%       Kdual = 4 * keff * v * T^2
%
%
%  Detection relation - Eq. (10):
%
%       P = 1/2 * (1 - cos(phi))
%
%
%  PURPOSE:
%
%  1) Show that phase grows linearly with angular velocity.
%  2) Determine the angular velocities corresponding to pi and 2*pi.
%  3) Show that transition probability repeats as Omega increases.
%  4) Demonstrate how reducing the scale factor increases the spacing
%     between interference fringes in angular-velocity space.
%
%
%  IMPORTANT:
%
%  The transition probability is evaluated here using the phase of
%  ONE ideal interferometer.
%
%  The dual-interferometer differential phase is plotted separately
%  as the processed rotation observable.
%
%  No new experimental parameters are introduced in this test.
%
% ========================================================================


%% 1. CAIG physical parameters

% ------------------------------------------------------------------------
% T and v
%
% Source:
% Tackmann et al. (2012)
%
% Reason:
% Zhang et al. use T and v in the rotation model but do not provide
% numerical values. The adopted experiment uses comparable
% 87Rb Raman atom-interferometer techniques.
% ------------------------------------------------------------------------

T = 24.7e-3;                  % Pulse separation time [s]

v = 2.79;                     % Atomic velocity [m/s]


% ------------------------------------------------------------------------
% 87Rb D2 wavelength
%
% Source:
% D. A. Steck, "Rubidium 87 D Line Data"
% ------------------------------------------------------------------------

lambdaD2 = 780.241209686e-9;  % [m]


% Optical wave number

k = 2*pi/lambdaD2;            % [1/m]


% Effective wave vector
%
% V1 approximation:
% counterpropagating Raman beams

keff = 2*k;                   % [1/m]


%% 2. Scale factors

% Single interferometer

Ksingle = 2*keff*v*T^2;       % [s]


% Dual-interferometer differential signal

Kdual = 4*keff*v*T^2;         % [s]


%% 3. Characteristic angular velocities

% ------------------------------------------------------------------------
% These values indicate when the corresponding phase reaches
% pi or 2*pi.
%
% NOTE:
%
% Calling these values "fully unambiguous limits" would be too strong
% because Eq. (10) also has a +/- phase ambiguity.
%
% They are therefore treated here as characteristic fringe boundaries.
% ------------------------------------------------------------------------


% Single interferometer

OmegaPiSingle = pi/Ksingle;

Omega2PiSingle = 2*pi/Ksingle;


% Dual differential phase

OmegaPiDual = pi/Kdual;

Omega2PiDual = 2*pi/Kdual;


%% 4. Angular velocity sweep

% Test-only sweep.
%
% The upper limit is chosen so that several interference fringes
% can be visualized.
%
% This is NOT an experimental CAIG parameter.

OmegaMax = 1.5e-4;            % [rad/s]

Omega = linspace( ...
    -OmegaMax, ...
     OmegaMax, ...
     4000).';


%% 5. Rotation phases

phiSingle = Ksingle*Omega;

phiDual = Kdual*Omega;


%% 6. Ideal transition probability
%
% Zhang et al. Eq. (10)
%
% Applied here to the ideal single-interferometer rotation phase.

Psingle = 0.5*(1 - cos(phiSingle));


%% 7. Reduced-scale-factor comparison
%
% Zhang et al. state that reducing the scale factor increases
% the angular-velocity range corresponding to a given phase interval.
%
% To demonstrate that relationship, we create a HYPOTHETICAL
% scale factor equal to half of the V1 value.
%
% This is ONLY a simulation comparison.
% It is not an experimental parameter.

Kreduced = 0.5*Ksingle;


phiReduced = Kreduced*Omega;

Preduced = 0.5*(1 - cos(phiReduced));


% Characteristic pi and 2*pi angular velocities
% for the reduced scale factor

OmegaPiReduced = pi/Kreduced;

Omega2PiReduced = 2*pi/Kreduced;


%% 8. Display numerical results

fprintf('\n');
fprintf('============================================\n');
fprintf('SCALE FACTOR AND DYNAMIC RANGE TEST\n');
fprintf('============================================\n');

fprintf('\nScale factors:\n');

fprintf('Ksingle = %.6e s\n',Ksingle);

fprintf('Kdual   = %.6e s\n',Kdual);


fprintf('\n--------------------------------------------\n');
fprintf('SINGLE INTERFEROMETER\n');
fprintf('--------------------------------------------\n');

fprintf('Omega at phi = pi    : %.6e rad/s\n',...
        OmegaPiSingle);

fprintf('Omega at phi = 2*pi  : %.6e rad/s\n',...
        Omega2PiSingle);


fprintf('\n--------------------------------------------\n');
fprintf('DUAL DIFFERENTIAL PHASE\n');
fprintf('--------------------------------------------\n');

fprintf('Omega at phiDiff = pi   : %.6e rad/s\n',...
        OmegaPiDual);

fprintf('Omega at phiDiff = 2*pi : %.6e rad/s\n',...
        Omega2PiDual);


fprintf('\n--------------------------------------------\n');
fprintf('REDUCED SCALE FACTOR TEST\n');
fprintf('--------------------------------------------\n');

fprintf('Kreduced = %.6e s\n',Kreduced);

fprintf('Omega at phi = pi    : %.6e rad/s\n',...
        OmegaPiReduced);

fprintf('Omega at phi = 2*pi  : %.6e rad/s\n',...
        Omega2PiReduced);


%% 9. Plot - Phase versus angular velocity

figure;


subplot(3,1,1)

plot(Omega,phiSingle,...
    'LineWidth',1.5)

hold on

plot(Omega,phiDual,...
    '--',...
    'LineWidth',1.5)


yline(pi,':','\pi');

yline(-pi,':','-\pi');

yline(2*pi,':','2\pi');

yline(-2*pi,':','-2\pi');


grid on

xlabel('\Omega [rad/s]')

ylabel('Phase [rad]')

legend( ...
    'Single-interferometer phase',...
    'Dual differential phase',...
    'Location','best')

title('CAIG Phase vs Angular Velocity')


%% 10. Plot - Interference fringes versus angular velocity

subplot(3,1,2)

plot(Omega,Psingle,...
    'LineWidth',1.5)

hold on


% Characteristic single-interferometer fringe locations

xline(OmegaPiSingle,'--');

xline(-OmegaPiSingle,'--');

xline(Omega2PiSingle,':');

xline(-Omega2PiSingle,':');


grid on

xlabel('\Omega [rad/s]')

ylabel('Transition Probability')

title('Ideal CAIG Interference Fringe vs Angular Velocity')


%% 11. Plot - Effect of scale-factor reduction

subplot(3,1,3)

plot(Omega,Psingle,...
    'LineWidth',1.5)

hold on

plot(Omega,Preduced,...
    '--',...
    'LineWidth',1.5)


grid on

xlabel('\Omega [rad/s]')

ylabel('Transition Probability')

legend( ...
    'Original K',...
    'Reduced K = 0.5 K',...
    'Location','best')

title('Effect of Scale Factor on Fringe Spacing')