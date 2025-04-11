# -*- coding: utf-8 -*-
"""
Created on Fri Apr 11 17:49:28 2025

@author: leonb
"""

import bpy
import csv
import os

# Obtenir le chemin du dossier du fichier .blend
blend_dir = bpy.path.abspath("//")  # "//" représente le dossier du fichier .blend
csv_file_path = os.path.join(blend_dir, "csv.csv")  # Remplace par le nom réel

# Vérifier si le fichier existe
if not os.path.exists(csv_file_path):
    raise FileNotFoundError(f"Le fichier CSV '{csv_file_path}' est introuvable.")

# Charger les données CSV
with open(csv_file_path, 'r', newline='') as file:
    reader = csv.reader(file)
    data = list(reader)

# Vérification des données
if len(data) < 3:
    raise ValueError("Le fichier CSV doit contenir au moins 3 lignes pour x, y et z.")

# Récupérer les valeurs
x_values = list(map(float, data[0]))
y_values = list(map(float, data[1]))
z_values = list(map(float, data[2]))

# Vérifier que toutes les colonnes ont la même longueur
num_frames = min(len(x_values), len(y_values), len(z_values))

# Obtenir l'objet sélectionné
obj = bpy.context.object
if obj is None:
    raise ValueError("Sélectionnez un objet avant d'exécuter le script.")

# Appliquer les keyframes
for frame in range(num_frames):
    obj.location = (x_values[frame], y_values[frame], z_values[frame])
    obj.keyframe_insert(data_path="location", frame=frame + 1)

print(f"Animation appliquée avec {num_frames} keyframes.")
