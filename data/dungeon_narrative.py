"""Narrative text used by dungeons.

Keep story presentation separate from dungeon mechanics so future GUI clients can
reuse the same scenes without parsing terminal strings from application code.
"""

BLACK_FLEET_NARRATIVE: dict[str, str] = {
    "entrance": (
        "Przed tobą rozciąga się cmentarzysko okrętów skute lodem. "
        "Połamane maszty sterczą z białej równiny niczym nagrobki, a między "
        "kadłubami słychać skrzypienie drewna poruszanego przez wiatr.\n\n"
        "Na największym z wraków wciąż powiewa czarna bandera. Medalion Czarnej "
        "Floty robi się lodowato zimny w twojej dłoni."
    ),
    "frozen_deck": (
        "Stawiasz stopę na zamarzniętym pokładzie pierwszego wraku. Drewno jęczy "
        "pod grubą warstwą lodu, choć morze wokół pozostaje nieruchome.\n\n"
        "Z wnętrza okrętu dochodzą powolne kroki. Ktoś nadal pełni tu wachtę."
    ),
    "wreck_passage": (
        "Zerwane maszty tworzą chwiejne przejście nad czarną wodą. Pod lodem "
        "widać sylwetki kolejnych statków, które nigdy nie dotarły do brzegu.\n\n"
        "Na sąsiednim pokładzie porusza się cień, a potem znika za rozdartym "
        "żaglem Czarnej Floty."
    ),
    "cargo_hold": (
        "Schodzisz głęboko pod pokład. Zamarznięta woda pokrywa podłogę, a w "
        "lodzie tkwią beczki, skrzynie i szczątki dawnej załogi.\n\n"
        "Gdzieś dalej naprężony łańcuch przesuwa się po drewnie. Sam."
    ),
    "upper_deck": (
        "Wychodzisz na otwarty pokład. Wiatr natychmiast uderza w twarz drobnym "
        "lodem, a widoczność między wrakami niemal znika.\n\n"
        "Przez zamieć dostrzegasz błysk lontu. Ktoś przy jednym z dział właśnie "
        "zajął pozycję."
    ),
    "officer_quarters": (
        "Drzwi kajut noszą wyblakłe stopnie i nazwiska. Na ścianach wciąż wiszą "
        "mapy morskie, całe pokryte szronem.\n\n"
        "Na jednym ze stołów leży otwarty dziennik pokładowy. Ostatni wpis urywa "
        "się w połowie zdania. Z sąsiedniej kajuty dobiega odgłos odsuwanego krzesła."
    ),
    "first_officer_intro": (
        "Powolne kroki odbijają się echem po korytarzu.\n\n"
        "Z ciemności wyłania się wysoka postać w zniszczonym mundurze. Na jego "
        "ramionach wciąż widać oznaczenia Czarnej Floty, a widmowa dłoń spoczywa "
        "na rękojeści szabli.\n\n"
        "— Admirał nie przyjmuje gości."
    ),
    "flagship_approach": (
        "Przed tobą wyrasta największy ze wszystkich wraków — okręt flagowy. "
        "Jego kadłub jest niemal całkowicie skuty czarnym lodem, lecz wygląda, "
        "jakby mimo upływu lat wciąż czekał na rozkaz wypłynięcia.\n\n"
        "Na burcie widnieje znak Czarnej Floty. Gdzieś wysoko rozlega się dźwięk "
        "okrętowego dzwonu.\n\nJeden raz.\nDrugi.\nTrzeci."
    ),
    "varek_intro": (
        "Drzwi kabiny admirała otwierają się bez niczyjego dotyku. Na pokład "
        "wychodzi mężczyzna w czarnym mundurze, którego ciało dawno powinno "
        "obrócić się w proch. W jego oczach płonie blade światło.\n\n"
        "Admirał Varek spogląda na skute lodem okręty, a potem powoli wyciąga "
        "szablę. Wokół dział zaczynają materializować się widmowi kanonierzy.\n\n"
        "— Moja flota jeszcze nie zatonęła."
    ),
}
