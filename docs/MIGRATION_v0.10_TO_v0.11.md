# Migracja zapisu v0.10.x → v0.11.0

Od v0.11.0 zapis jest przechowywany poza folderem gry.

Na Windows:

```text
%LOCALAPPDATA%\EchoesOfPythonia\saves\save_1.json
```

## Najbezpieczniejsza aktualizacja

1. Nie usuwaj jeszcze folderu v0.10.x.
2. Zmień jego nazwę np. na `echoes_of_pythonia_v0.10.0`.
3. Rozpakuj v0.11.0 obok niego, tak aby oba foldery miały tego samego rodzica.
4. Uruchom `python main.py` z v0.11.0.
5. Gra powinna wyświetlić ekran `MIGRACJA ZAPISU`.
6. W menu głównym wybierz `Wczytaj grę` i sprawdź postać.
7. Zapisz grę ponownie już z v0.11.0.
8. Dopiero po tym możesz usunąć stary folder v0.10.x.

Gra nie usuwa starego pliku podczas migracji.

## Jeśli automatyczna migracja nie znajdzie zapisu

Skopiuj ręcznie:

```text
STARY_FOLDER\saves\save_1.json
```

do:

```text
NOWY_FOLDER\saves\save_1.json
```

Następnie uruchom v0.11.0 ponownie. Gra wykryje lokalny stary save i przeniesie go do stałego katalogu użytkownika.
