% Chargez carte 3D. Spécifiez le seuil pour considérer les cellules comme sans obstacle.
mapData = load('map3D_occupationV2B.mat'); %A modifier par leur carte
omap = mapData.map3D;
omap.FreeThreshold = 0.5;
% Gonflez la carte d'occupation pour ajouter une zone tampon pour un fonctionnement sûr autour des obstacles.
%inflate(omap, 1); % À AJUSTER SUR LA CARTE DES AUTRES SUIVANT LA LARGEUR DU DRONE, LONG EN TEMPS DE CALCUL A PARTIR DE 3, ON PEUT PRENDRE 1 POUR LES TESTS ; on le supprime car fait buguer le programme
% Créez un objet d'espace d'état SE(3) avec des limites pour les variables d'état.
ss = stateSpaceSE3([-1.5 1.5; -1.5 1.5; 0 2; inf inf; inf inf; inf inf; inf inf]);
% Créez un validateur d'état de carte d'occupation 3D à l'aide de l'espace d'état créé.
% Attribuez la carte d'occupation à l'objet validateur d'état.
% Spécifiez l’intervalle de distance d’échantillonnage.
sv = validatorOccupancyMap3D(ss, ...
  'Map', omap, ...
  'ValidationDistance', 0.05);
% Créez un planificateur de chemin en étoile RRT avec une distance de connexion maximale accrue et un nombre maximal d'itérations réduit.
% Spécifiez une fonction d'objectif personnalisée qui détermine qu'un chemin atteint l'objectif si la distance euclidienne jusqu'à la cible est inférieure à un seuil de 1 mètre.
planner = plannerRRTStar(ss, sv, ...
       'MaxConnectionDistance', 0.06, ...
       'MaxIterations', 1000, ...
       'GoalReachedFcn', @(~, s, g)(norm(s(1:3)-g(1:3))<0.5), ...
       'GoalBias', 0.1);
% Spécifiez les poses de départ et d’objectif: à modifier suivant la carte
start = [0.5 0 0.2 0.7 0.2 0 0.1];
goal = [-1 0 0.5 0 0 0.1 0.6];
% Configurez le générateur de nombres aléatoires pour un résultat reproductible.
rng(1, "twister");
% Planifiez le chemin.
[pthObj, solnInfo] = plan(planner, start, goal);
% Ajouter les points de départ et d'arrivée pour garantir que la spline passe bien par eux
% Ajouter un point à la fin de la trajectoire pour garantir qu'il atteigne l'objectif
newPath = [start(1:3); pthObj.States(:, 1:3); goal(1:3)];
% Répéter les étapes d'interpolation
t = 1:size(newPath, 1);
tt = linspace(1, size(newPath, 1), 200);  % Nouveau vecteur de temps pour interpolation
splinePath = csaps(t, newPath', 0.01, tt);  % Appliquer la spline
% Assurez-vous que la spline passe par l'objectif
splinePath(:, end) = goal(1:3)';  % Forcer le dernier point à être égal à l'objectif
% Visualisez les deux chemins prévus: à remplacer par exporter la trajectoire
show(omap);
axis equal;
view([-10 55]);
hold on;
% État de départ
scatter3(start(1), start(2), start(3), "g", "filled");
% État cible
scatter3(goal(1), goal(2), goal(3), "r", "filled");
% Trajectoire d'origine
plot3(pthObj.States(:, 1), pthObj.States(:, 2), pthObj.States(:, 3), ...
   "b-", 'LineWidth', 2, 'DisplayName', 'Trajectoire RRT*');
% Trajectoire interpolée avec une spline
plot3(splinePath(1, :), splinePath(2, :), splinePath(3, :), ...
   "m-", 'LineWidth', 2, 'DisplayName', 'Trajectoire Spline');
% Légende
legend('Location', 'Best');

hold off;
%enregistrer la trajectoire
writematrix(splinePath, 'trajectoirecsv.csv')