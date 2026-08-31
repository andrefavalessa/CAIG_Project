clear;
clc;
close all;

%% ========================================================================
%  TEST - CAIG phase-to-population conversion
%
%  Main model:
%  Zhang et al. (2019)
%
%  Eq. (10):
%
%       P = 1/2 * (1 - cos(DeltaPhi))
%
%  Purpose:
%
%  1) Verify the periodic behavior of the transition probability.
%  2) Show the 2*pi phase ambiguity.
%  3) Show that +phi and -phi produce the same probability.
%  4) Demonstrate why P -> phi is not uniquely invertible.
%
%  No external experimental parameters are used in this test.
%
% ========================================================================


%% 1. Generate phase sweep

% Test phase range:
%
% -4*pi to +4*pi
%
% This is only a simulation choice used to visualize several
% interference fringes.

phi = linspace(-4*pi,4*pi,2000).';


%% 2. Transition probability
%
% Zhang et al. Eq. (10)

P = 0.5*(1 - cos(phi));


%% 3. Attempt to recover phase from probability
%
% From:
%
% P = 1/2*(1-cos(phi))
%
% we obtain:
%
% cos(phi) = 1 - 2P
%
% therefore:
%
% phi = acos(1-2P)
%
% HOWEVER:
%
% acos returns only its principal value in [0,pi].
% Therefore this does NOT uniquely recover the original phase.

phiRecovered = acos(1 - 2*P);


%% 4. Demonstrate sign ambiguity

phiA = pi/3;
phiB = -pi/3;

PA = 0.5*(1 - cos(phiA));
PB = 0.5*(1 - cos(phiB));


%% 5. Demonstrate 2*pi ambiguity

phiC = pi/3;
phiD = pi/3 + 2*pi;

PC = 0.5*(1 - cos(phiC));
PD = 0.5*(1 - cos(phiD));


%% 6. Display numerical examples

fprintf('\n============================================\n');
fprintf('PHASE DETECTION TEST\n');
fprintf('============================================\n');

fprintf('\nSign ambiguity:\n');

fprintf('phiA = %+8.5f rad -> P = %.6f\n',...
        phiA,PA);

fprintf('phiB = %+8.5f rad -> P = %.6f\n',...
        phiB,PB);


fprintf('\n2*pi ambiguity:\n');

fprintf('phiC = %+8.5f rad -> P = %.6f\n',...
        phiC,PC);

fprintf('phiD = %+8.5f rad -> P = %.6f\n',...
        phiD,PD);


%% 7. Plot transition probability

figure;

subplot(2,1,1)

plot(phi,P,'LineWidth',1.5)

grid on

xlabel('\Delta\phi [rad]')
ylabel('Transition Probability')

title('CAIG Interference Fringe - Zhang et al. Eq. (10)')

xline(-2*pi,'--')
xline(0,'--')
xline(2*pi,'--')


%% 8. Plot attempted phase recovery

subplot(2,1,2)

plot(phi,phiRecovered,'LineWidth',1.5)

grid on

xlabel('True phase \Delta\phi [rad]')
ylabel('Recovered phase [rad]')

title('Phase Recovered Using acos(1 - 2P)')