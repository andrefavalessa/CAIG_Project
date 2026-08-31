clear;
clc;
close all;

%% ========================================================================
%  TEST - Rotation-gravity coupling term in dual-interferometer CAIG
%
%  Main model:
%  Zhang et al. (2019)
%
%  Eq. (7):
%
%  phi_total =
%      keff . g * T^2
%      + phi_rot
%      - 2 * keff . (Omega x g) * T^3
%      + DeltaPhi0
%
%  Purpose of this test:
%
%  1) Make the Omega x g term non-zero by tilting gravity.
%  2) Verify the term analytically.
%  3) Verify that it is common to both interferometers.
%  4) Verify that it cancels in:
%
%       phiTot1 - phiTot2
%
%
%  IMPORTANT:
%
%  alphaG = 10 deg is only a simulation-test choice.
%  It is NOT taken from Zhang et al. or from an experiment.
%
% ========================================================================


%% 1. Simulation parameters

Fs = 5;                       % [Hz] - Zhang et al. simulation
duration = 20;                % [s] - simulation choice

t = (0:1/Fs:duration-1/Fs).';

N = length(t);


%% 2. True angular velocity

% Ground-truth rotation used only to test the model

Omega0 = 1e-5;                % [rad/s] - simulation choice
f = 0.1;                      % [Hz] - simulation choice

OmegaVec = zeros(N,3);

% Rotation around Y-axis
OmegaVec(:,2) = Omega0 * sin(2*pi*f*t);


%% 3. CAIG physical parameters

% ------------------------------------------------------------------------
% Parameters adopted from comparable 87Rb experiment:
% Tackmann et al. (2012)
% ------------------------------------------------------------------------

T = 24.7e-3;                  % Pulse separation time [s]
v = 2.79;                     % Atomic velocity [m/s]


% ------------------------------------------------------------------------
% 87Rb D2 transition
% ------------------------------------------------------------------------

lambdaD2 = 780.241209686e-9;  % [m]

k = 2*pi/lambdaD2;            % Single-photon wave number [1/m]

% Counterpropagating Raman approximation
keff = 2*k;                   % Effective wave vector [1/m]


% ------------------------------------------------------------------------
% Standard gravity
% ------------------------------------------------------------------------

g0 = 9.80665;                 % [m/s^2]


%% 4. CAIG geometry

% Coordinate convention:
%
% Cloud 1 -> +X
% Cloud 2 -> -X
%
% keff -> +Z
%
% Omega -> Y
%
% Gravity is intentionally tilted from -Z toward -X
% in order to make the Omega x g term non-zero.

keffVec = [0 0 keff];

v1Vec = [ v 0 0];
v2Vec = [-v 0 0];


%% 5. Tilted gravity - TEST ONLY

alphaG = deg2rad(10);         % Test-only tilt angle

gVec = [ ...
    -g0*sin(alphaG), ...
     0, ...
    -g0*cos(alphaG) ...
    ];

% Check that gravity magnitude is still g0
gMagnitude = norm(gVec);


%% 6. Build matrices

v1Matrix = repmat(v1Vec,N,1);
v2Matrix = repmat(v2Vec,N,1);

gMatrix = repmat(gVec,N,1);


%% 7. Rotation phase - Loop 1
%
% Eq. (6):
%
% phi_rot = -2 * keff . (Omega x v) * T^2

OmegaCrossV1 = cross(OmegaVec,v1Matrix,2);

phiRot1 = -2*T^2*(OmegaCrossV1*keffVec.');


%% 8. Rotation phase - Loop 2

OmegaCrossV2 = cross(OmegaVec,v2Matrix,2);

phiRot2 = -2*T^2*(OmegaCrossV2*keffVec.');


%% 9. Gravity phase
%
% Eq. (7):
%
% phi_g = keff . g * T^2

phiGravityValue = dot(keffVec,gVec)*T^2;

phiGravity = phiGravityValue*ones(N,1);


%% 10. Rotation-gravity coupling term
%
% Eq. (7):
%
% phi_OmegaG =
%      -2 * keff . (Omega x g) * T^3

OmegaCrossG = cross(OmegaVec,gMatrix,2);

phiOmegaG = -2*T^3*(OmegaCrossG*keffVec.');


%% 11. Analytical check of Omega x g term
%
% For this geometry:
%
% Omega = [0 Omega_y 0]
%
% g =
% [-g*sin(alphaG), 0, -g*cos(alphaG)]
%
%
% Therefore:
%
% keff . (Omega x g)
% =
% keff * Omega_y * g * sin(alphaG)
%
%
% so:
%
% phiOmegaG =
% -2*keff*g*sin(alphaG)*T^3*Omega_y

KOmegaG = ...
    -2*keff*g0*sin(alphaG)*T^3;

phiOmegaGCheck = ...
    KOmegaG*OmegaVec(:,2);

errorOmegaG = max(abs( ...
    phiOmegaG - phiOmegaGCheck));


%% 12. Ideal random/common phase
%
% V1 ideal assumption:
% no random pulse phase yet

phi0 = zeros(N,1);


%% 13. Total phase of both interferometers
%
% Eq. (8)

phiTot1 = ...
      phiGravity ...
    + phiRot1 ...
    + phiOmegaG ...
    + phi0;

phiTot2 = ...
      phiGravity ...
    + phiRot2 ...
    + phiOmegaG ...
    + phi0;


%% 14. Differential phase
%
% Common terms should cancel

phiDiffFull = ...
    phiTot1 - phiTot2;


%% 15. Rotation-only differential phase

phiDiffRotationOnly = ...
    phiRot1 - phiRot2;


%% 16. Common-mode rejection test

commonModeError = max(abs( ...
    phiDiffFull - phiDiffRotationOnly));


%% 17. Analytical rotation checks

Ksingle = 2*keff*v*T^2;

Kdual = 4*keff*v*T^2;


phiRot1Check = ...
    Ksingle*OmegaVec(:,2);

phiRot2Check = ...
   -Ksingle*OmegaVec(:,2);

phiDiffCheck = ...
    Kdual*OmegaVec(:,2);


errorRot1 = max(abs( ...
    phiRot1 - phiRot1Check));

errorRot2 = max(abs( ...
    phiRot2 - phiRot2Check));

errorDiff = max(abs( ...
    phiDiffFull - phiDiffCheck));


%% 18. Display results

fprintf('\n============================================\n');
fprintf('ROTATION-GRAVITY COUPLING TEST\n');
fprintf('============================================\n');

fprintf('Gravity tilt angle = %.2f deg\n',...
        rad2deg(alphaG));

fprintf('Gravity magnitude = %.8f m/s^2\n',...
        gMagnitude);

fprintf('\n');

fprintf('Gravity phase = %.6e rad\n',...
        phiGravityValue);

fprintf('Maximum Omega x g phase = %.6e rad\n',...
        max(abs(phiOmegaG)));

fprintf('Maximum rotation phase loop 1 = %.6e rad\n',...
        max(abs(phiRot1)));

fprintf('Maximum rotation phase loop 2 = %.6e rad\n',...
        max(abs(phiRot2)));

fprintf('Maximum differential phase = %.6e rad\n',...
        max(abs(phiDiffFull)));


fprintf('\n============================================\n');
fprintf('NUMERICAL VERIFICATION\n');
fprintf('============================================\n');

fprintf('Omega x g analytical error = %.3e rad\n',...
        errorOmegaG);

fprintf('Loop 1 rotation error = %.3e rad\n',...
        errorRot1);

fprintf('Loop 2 rotation error = %.3e rad\n',...
        errorRot2);

fprintf('Full differential error = %.3e rad\n',...
        errorDiff);

fprintf('Common-mode rejection residual = %.3e rad\n',...
        commonModeError);


%% 19. Plot - Omega x g term

figure;

subplot(3,1,1)

plot(t,OmegaVec(:,2),'LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('\Omega_y [rad/s]')

title('True Angular Velocity')


subplot(3,1,2)

plot(t,phiOmegaG,'LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('\phi_{\Omega g} [rad]')

title('Rotation-Gravity Coupling Term')


subplot(3,1,3)

plot(t,phiRot1,'LineWidth',1.5)

hold on

plot(t,phiOmegaG,'--','LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('Phase [rad]')

legend('\phi_{rot,1}',...
       '\phi_{\Omega g}')

title('Rotation Phase vs Rotation-Gravity Correction')


%% 20. Plot - Common-mode rejection

figure;

subplot(3,1,1)

plot(t,phiTot1 - phiGravity,'LineWidth',1.5)

hold on

plot(t,phiTot2 - phiGravity,'--','LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('Phase [rad]')

legend('\phi_{tot,1}-\phi_g',...
       '\phi_{tot,2}-\phi_g')

title('Individual Phases Including Omega x g Term')


subplot(3,1,2)

plot(t,phiDiffFull,'LineWidth',1.5)

hold on

plot(t,phiDiffRotationOnly,'--','LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('Phase [rad]')

legend('Full differential phase',...
       'Rotation-only differential phase')

title('Common-Mode Rejection')


subplot(3,1,3)

plot(t,phiDiffFull - phiDiffRotationOnly,...
     'LineWidth',1.5)

grid on

xlabel('Time [s]')
ylabel('Residual [rad]')

title('Common-Mode Cancellation Residual')