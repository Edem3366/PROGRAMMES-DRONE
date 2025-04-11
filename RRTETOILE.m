mapData = load("carte3D.mat"); %importe une carte 3D
omap = mapData.omap; %extrait la carte d'occupation 3D
omap.FreeThreshold = 0.5; %seuil definissant les cellules comme obstacles

inflate(omap,1) %gonfle les batiments de la carte d'une unite

ss = stateSpaceSE3([0 220;0 220;0 100;inf inf;inf inf;inf inf;inf inf]); %cree un espace d'etat et definit des limites d'etat (positions et quaternions max et min: x; y; z; qx; qy; qz; qw), restreints les positions et orientations du drone possibles

sv = validatorOccupancyMap3D(ss, ...
     Map = omap, ...
     ValidationDistance = 0.1); 
%validateur d'etat qui verifie que la trajectoire generee ne penetre pas dans les obstacles (ici la marge de securite est de 0.1)
     
planner = plannerRRTStar(ss,sv, ...
          MaxConnectionDistance = 50, ...
          MaxIterations = 1000, ...
          GoalReachedFcn = @(~,s,g)(norm(s(1:3)-g(1:3))<1), ...
          GoalBias = 0.1); 
          %planificateur qui utilise l'algorithme RRT*, les parametres sont ajustables
          
start = [40 180 25 0.7 0.2 0 0.1]; %definie la position et l'orientation du drone au depart

goal = [150 33 35 0.3 0 0.1 0.6]; %definie la position et l'orientation du drone a l'arrivee

rng(1,"twister");
%initialise le generateur de nombres aleatoires qui permet de reproduire les memes operations aleatoires, garantissant ainsi les memes resultats a chaque execution du programme

[pthObj,solnInfo] = plan(planner,start,goal);
%excute l'algorithme RRT*

show(omap) %affiche la carte
axis equal %ajuste l'echelle des axes
view([-10 55]) %definie l'angle de vue
hold on %garde la carte affichee tout en y ajoutant les elements suivants

scatter3(start(1,1),start(1,2),start(1,3),"g","filled") %affiche le point de depart

scatter3(goal(1,1),goal(1,2),goal(1,3),"r","filled") %affiche le point d'arrivee

plot3(pthObj.States(:,1),pthObj.States(:,2),pthObj.States(:,3), ...
      "r-",LineWidth=2) %trace la trajectoire du drone