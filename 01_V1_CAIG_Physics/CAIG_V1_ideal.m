clear;
clc;
close all;

%% CAIG V1 - Ideal dual-interferometer model
%
% Main model: Zhang et al. (2019), Eqs. (6)-(10).
%
% External parameters:
% T = 24.7 ms, v = 2.79 m/s
%   Source: Tackmann et al. (2012), comparable 87Rb Raman gyroscope.
%
% lambdaD2 = 780.241209686 nm
%   Source: Steck, Rubidium 87 D Line Data.
%
% See README_V1.md for complete parameter traceability.

%% Simulation

Fs = 5;                       % [Hz], Zhang et al. (2019)
duration = 20;                % [s], simulation choice

t = (0:1/Fs:duration-1/Fs).';
N = length(t);

%% Ground-truth rotation

Omega0 = 1e-5;                % [rad/s], simulation choice
f = 0.1;                      % [Hz], simulation choice

OmegaVec = zeros(N,3);
OmegaVec(:,2) = Omega0*sin(2*pi*f*t);

%% Physical parameters

T = 24.7e-3;                  % [s], Tackmann et al. (2012)
v = 2.79;                     % [m/s], Tackmann et al. (2012)

lambdaD2 = 780.241209686e-9;  % [m], Steck
k = 2*pi/lambdaD2;

keff = 2*k;                   % [1/m], counterpropagating Raman approx.

g0 = 9.80665;                 % [m/s^2], standard gravity

%% Geometry

keffVec = [0 0 keff];

v1Vec = [ v 0 0];
v2Vec = [-v 0 0];

gVec = [0 0 -g0];

v1Matrix = repmat(v1Vec,N,1);
v2Matrix = repmat(v2Vec,N,1);
gMatrix  = repmat(gVec,N,1);

%% Eq. (6) - Rotation phase

phiRot1 = -2*T^2 * ...
    (cross(OmegaVec,v1Matrix,2)*keffVec.');

phiRot2 = -2*T^2 * ...
    (cross(OmegaVec,v2Matrix,2)*keffVec.');

%% Eq. (7) - Common phase terms

phiGravityValue = dot(keffVec,gVec)*T^2;
phiGravity = phiGravityValue*ones(N,1);

phiOmegaG = -2*T^3 * ...
    (cross(OmegaVec,gMatrix,2)*keffVec.');

% Ideal V1: random three-pulse phase is neglected
phi0 = zeros(N,1);

%% Eq. (8) - Total phases

phiTot1 = phiGravity + phiRot1 + phiOmegaG + phi0;
phiTot2 = phiGravity + phiRot2 + phiOmegaG + phi0;

%% Eq. (9) - Differential phase

phiDiff = phiTot1 - phiTot2;

%% Eq. (10) - Ideal transition probability

P1 = 0.5*(1-cos(phiTot1));
P2 = 0.5*(1-cos(phiTot2));

%% Scale factors and validation

Ksingle = 2*keff*v*T^2;
Kdual   = 4*keff*v*T^2;

phiRot1Check =  Ksingle*OmegaVec(:,2);
phiRot2Check = -Ksingle*OmegaVec(:,2);
phiDiffCheck =  Kdual*OmegaVec(:,2);

fprintf('Ksingle = %.6e s\n',Ksingle);
fprintf('Kdual   = %.6e s\n',Kdual);

fprintf('Loop 1 error = %.3e rad\n', ...
    max(abs(phiRot1-phiRot1Check)));

fprintf('Loop 2 error = %.3e rad\n', ...
    max(abs(phiRot2-phiRot2Check)));

fprintf('Differential error = %.3e rad\n', ...
    max(abs(phiDiff-phiDiffCheck)));

%% Plots

figure;

subplot(4,1,1)
plot(t,OmegaVec(:,2),'LineWidth',1.5)
grid on
ylabel('\Omega_y [rad/s]')
title('Ground-Truth Angular Velocity')

subplot(4,1,2)
plot(t,phiRot1,'LineWidth',1.5)
hold on
plot(t,phiRot2,'--','LineWidth',1.5)
plot(t,phiDiff,':','LineWidth',1.5)
grid on
ylabel('Phase [rad]')
legend('\phi_{rot,1}','\phi_{rot,2}','\phi_{diff}')
title('Rotation Phase')

subplot(4,1,3)
plot(t,phiTot1-phiGravity,'LineWidth',1.5)
hold on
plot(t,phiTot2-phiGravity,'--','LineWidth',1.5)
grid on
ylabel('Phase [rad]')
legend('Loop 1','Loop 2')
title('Total Phase Without Common Gravity for Display')

subplot(4,1,4)
plot(t,P1,'LineWidth',1.5)
hold on
plot(t,P2,'--','LineWidth',1.5)
grid on
xlabel('Time [s]')
ylabel('Probability')
legend('P_1','P_2')
title('Ideal Transition Probability')