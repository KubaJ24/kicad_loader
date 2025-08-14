#!/usr/bin/env python3

import json
import os
import zipfile
import shutil
import time

user = os.getlogin()

prev_file_name = ""

# Czytanie konfiguracji z 'config.json'
with open(f"/home/{user}/.config/kicad_loader/config.json", "r") as file:
#with open("config.json", "r") as file:
    data = json.load(file)

# Zaczytywanie danych 
#version = data["version"]
version = "0.9.2.4"
downloads_dir = data["source_dir"]
tmp_dir = data["tmp_dir"]
kicad_mod_dir = data["kicad_mod_dir"]
model_dir = data["3dshapes_dir"]
sym_lib_dir = data["sym_lib_dir"]
lib_dir = data["lib_dir"]
element_list = data["element_list"]
allowed_extensions = tuple(data["extensions"])

print("Wersja programu: ", version)

# Sprawdzanie czy istnieje lista plików 
if not os.path.exists(element_list):
    with open(element_list, 'w') as f:
        pass
    print(f"Utworzono plik: {element_list}")

while True:
    time.sleep(1)
    # Czyszczenie tmp
    if os.path.exists(tmp_dir):
        for f in os.listdir(tmp_dir):
            p = os.path.join(tmp_dir, f)
            try:
                if os.path.isfile(p) or os.path.islink(p):
                    os.unlink(p)
                elif os.path.isdir(p):
                    shutil.rmtree(p)
                    print("Wyczyszczono: ", tmp_dir)
            except Exception as e:
                print(f"Błąd przy usuwaniu {tmp_dir}: {e}")
    else:
        os.makedirs(tmp_dir)

    try:
        files = [os.path.join(downloads_dir, f) for f in os.listdir(downloads_dir) if os.path.isfile(os.path.join(downloads_dir, f))]

        if files:
            zip_file = max(files, key=os.path.getmtime)
        else:
            print("Brak plików w downloads_dir.")

        if zip_file != prev_file_name:
            print("Najnowszy plik to:", zip_file)
            prev_file_name = zip_file

            # Rozpakowywanie plików do odpowiednich lokalizacji
            with zipfile.ZipFile(zip_file, 'r') as zip_ref:
                for name in zip_ref.namelist():
                    try:
                        if name.lower().endswith(allowed_extensions):
                            filename = os.path.basename(name)

                            with open(element_list, "r", encoding = "utf-8") as f:
                                lista_elementow_SamacSys = f.read()

                            if filename in lista_elementow_SamacSys:
                                print(f"{filename} był już dodany do biblioteki")
                            else:
                                with open(element_list, "a", encoding="utf-8") as f:
                                    f.write('\n' + filename)

                                # Footprinty
                                if name.endswith(".kicad_mod"):
                                    target_path = os.path.join(kicad_mod_dir, filename)

                                    with zip_ref.open(name) as source, open(target_path, "wb") as target:
                                        target.write(source.read())

                                    print("Rozpakowano:", filename, "do:", kicad_mod_dir)

                                # Modele 3D
                                if name.endswith(".stp" or ".step"):
                                    target_path = os.path.join(model_dir, filename)

                                    with zip_ref.open(name) as source, open(target_path, "wb") as target:
                                        target.write(source.read())

                                    print("Rozpakowano:", filename, "do:", model_dir)
                                
                                # Symbole
                                if name.endswith(".kicad_sym"):
                                    try:
                                        target_path = os.path.join(tmp_dir, filename)

                                        with zip_ref.open(name) as source, open(target_path, "wb") as target:
                                            target.write(source.read())

                                        # Usuwanie pierwszej i ostatniej linii z pliku
                                        with open(f"{tmp_dir}/{filename}", "r") as f:
                                            lines = f.readlines()
                                            if lines:
                                                lines = lines[1:-1]
                                        # Zapisywanie zmian
                                        with open(f"{tmp_dir}/{filename}", "w") as f:
                                            f.writelines(lines)

                                        with open(f"{tmp_dir}/{filename}", "r") as f:
                                            symbol = f.read()

                                        with open(f"{sym_lib_dir}", "r") as f:
                                            sym_lib = f.read()
                                            
                                        new_sym_lib = sym_lib.rstrip()[:-1] + symbol + "\n)"

                                        with open(f"{sym_lib_dir}", "w") as f:
                                            f.write(new_sym_lib)

                                        print(f"Dodano ", filename, "do ", sym_lib_dir)

                                    except Exception as e:
                                        print(f"Błąd przy otwieraniu {filename}: {e}")

                                # Plik lib
                                if name.endswith(".lib"):
                                    try:
                                        target_path = os.path.join(tmp_dir, filename)

                                        with zip_ref.open(name) as source, open(target_path, "wb") as target:
                                            target.write(source.read())

                                        # Usuwanie ostatniej linii z pliku
                                        with open(f"{tmp_dir}/{filename}", "r") as f:
                                            lines = f.readlines()
                                            if lines:
                                                lines = lines[:-1]
                                        # Zapisywanie zmian
                                        with open(f"{tmp_dir}/{filename}", "w") as f:
                                            f.writelines(lines)

                                        with open(f"{tmp_dir}/{filename}", "r") as f:
                                            lib_file = f.read()

                                        with open(f"{lib_dir}", "r") as f:
                                            lib = f.read()

                                        new_lib_file = lib.rstrip()[:-1] + lib_file + "\n)"

                                        with open(f"{lib_dir}", "w") as f:
                                            f.write(new_lib_file)

                                        print(f"Dodano ", filename, "do ", lib_dir)

                                    except Exception as e:
                                        print(f"Błąd przy otwieraniu {filename}: {e}")

                    except Exception as e:
                        print(f"Błąd przy kopiowaniu {name}: {e}")
    except Exception as e:
        print(f"Błąd: {e}")
    except KeyboardInterrupt:
            exit()
        
