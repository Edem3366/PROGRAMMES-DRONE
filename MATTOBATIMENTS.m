% Charger les données
data = load('V.mat');
% Stocker les sommets et faces
sommets = data.sommets;
faces = data.faces;
% Réindexer les faces (ajouter 1 à chaque indice pour passer de 0-basé à 1-basé)
faces = faces + 1;
% Vérification des indices pour éviter les erreurs
if max(faces(:)) > size(sommets, 1) || min(faces(:)) < 1
  error("Les indices des faces dépassent la taille des sommets !");
end
% Nombre de subdivisions par face (densification)
nSub = 5;  % Plus la valeur est grande, plus le maillage est dense
% Nouvelle liste de sommets et de faces
nSommets = size(sommets, 1);
newSommets = sommets;
newFaces = [];
% Générer les nouveaux sommets en respectant les formes d'origine
for i = 1:size(faces, 1)
  % Extraire les indices des sommets de la face
  idx = faces(i, :);
  facePoints = sommets(idx, :);
  % Définir le plan de la face avec une base locale
  origine = facePoints(1, :);
  v1 = facePoints(2, :) - origine;
  v2 = facePoints(3, :) - origine;
   % Calculer la normale pour garantir le bon alignement
  normale = cross(v1, v2);
  normale = normale / norm(normale);
  % Créer une base orthonormée locale (U, V, N)
  u = v1 / norm(v1);
  v = cross(normale, u);
  v = v / norm(v);
  % Trouver les coordonnées projetées de tous les sommets dans cette base
  localCoords = (facePoints - origine) * [u; v]';
  % Déterminer les limites de la face dans ce plan
  minU = min(localCoords(:, 1));
  maxU = max(localCoords(:, 1));
  minV = min(localCoords(:, 2));
  maxV = max(localCoords(:, 2));
  % Générer une grille de points dans ce plan
  indexGrid = zeros(nSub + 1, nSub + 1);
   for uStep = 0:nSub
      for vStep = 0:nSub
          % Interpolation dans le repère local
          localU = minU + (uStep / nSub) * (maxU - minU);
          localV = minV + (vStep / nSub) * (maxV - minV);
        
          % Conversion vers le repère global
          newPoint = origine + localU * u + localV * v;
        
          % Ajouter le nouveau sommet à la liste
          nSommets = nSommets + 1;
          newSommets(nSommets, :) = newPoint;
          indexGrid(uStep + 1, vStep + 1) = nSommets;
      end
  end
  % Connecter les nouveaux sommets pour former des triangles
  for uStep = 1:nSub
      for vStep = 1:nSub
          p1 = indexGrid(uStep, vStep);
          p2 = indexGrid(uStep + 1, vStep);
          p3 = indexGrid(uStep, vStep + 1);
          p4 = indexGrid(uStep + 1, vStep + 1);
          % Ajouter deux triangles pour former une grille fine
          newFaces = [newFaces; p1, p2, p4];  % Triangle 1
          newFaces = [newFaces; p1, p4, p3];  % Triangle 2
      end
  end
end
% Mettre à jour les sommets et faces
sommets = newSommets;
faces = newFaces;
% Extraire les indices uniques des sommets
indicesSommets = unique(faces(:));
% Extraire les coordonnées des bâtiments
points = sommets(indicesSommets, :);
% Vérification de l'orientation des coordonnées
points = points(:, [1, 3, 2]);  % Permuter Y et Z si nécessaire
% Création de la carte d'occupation 3D
map3D = occupancyMap3D(10);
% Définition de la pose du capteur (centre d'origine)
pose = [0 0 0 1 0 0 0];
% Portée maximale du capteur
maxRange = 1000;
% Insérer les points extraits dans la carte
insertPointCloud(map3D, pose, points, maxRange);
% Afficher la carte
show(map3D);
axis equal;  % Garde les proportions correctes
xlim([-5 5]);  % Ajuste la plage d'affichage en X
ylim([-5 5]);  % Ajuste la plage en Y
zlim([-5 5]);  % Ajuste la plage en Z
% Ajuster les axes pour une orientation correcte
set(gca, 'ZDir', 'normal');
% Afficher les axes et la grille
grid on;
axis on;
view(30, 30);
% Dessiner les nouvelles faces en conservant la géométrie d'origine
hold on;
for i = 1:size(faces, 1)
  % Extraire les indices de la face
  idx = faces(i, :);
   % Extraire les coordonnées des sommets de la face
  facePoints = sommets(idx, :);
   % Permuter Y et Z pour correction
  facePoints = facePoints(:, [1, 3, 2]);
   % Dessiner la face
  patch(facePoints(:, 1), facePoints(:, 2), facePoints(:, 3), 'b', 'FaceAlpha', 0.3);
end
hold off;
% Sauvegarder la carte mise à jour
save('map3D_occupation.mat', 'map3D');