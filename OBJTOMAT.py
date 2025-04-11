# -*- coding: utf-8 -*-
"""
Created on Fri Apr 11 17:41:10 2025

@author: leonb
"""

import numpy as np
from scipy.io import savemat  

def lire_obj(fichier_obj):
    """
    Lit un fichier .obj et extrait les sommets, les normales et les faces.
    """
    sommets = []
    normales = []
    faces = []

    with open(fichier_obj, 'r') as f:
        for ligne in f:
            ligne = ligne.strip()
            if ligne.startswith('v '):
                sommets.append([float(x) for x in ligne[2:].split()])
            elif ligne.startswith('vn '):
                normales.append([float(x) for x in ligne[3:].split()])
            elif ligne.startswith('f '):
                face_data = ligne[2:].split()
                face = []
                for vertex_data in face_data:
                    # Les indices dans les fichiers .obj commencent à 1, on les ajuste pour Python (0-based)
                    vertex_index = int(vertex_data.split('/')[0]) - 1
                    face.append(vertex_index)
                faces.append(face)

    return sommets, normales, faces

def convertir_en_mat(fichier_obj, fichier_mat):
    """
    Convertit un fichier .obj en un fichier .mat avec des matrices régulières.
    """
    sommets, normales, faces = lire_obj(fichier_obj)

    # Convertit les listes en matrices NumPy
    sommets = np.array(sommets, dtype=np.float64)
    normales = np.array(normales, dtype=np.float64)

    # Uniformiser la taille des faces
    max_face_len = max(len(face) for face in faces)  # Taille max des faces
    faces_padded = np.full((len(faces), max_face_len), -1, dtype=np.int32)  # Matrice remplie de -1

    for i, face in enumerate(faces):
        faces_padded[i, :len(face)] = face  # Remplissage des valeurs existantes

    # Crée un dictionnaire pour stocker les données
    data = {
        'sommets': sommets,
        'normales': normales,
        'faces': faces_padded  # Maintenant une vraie matrice
    }

    # Enregistre les données dans un fichier .mat
    savemat(fichier_mat, data)
    print(f"Conversion terminée. Fichier .mat créé: {fichier_mat}")
