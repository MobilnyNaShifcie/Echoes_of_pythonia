"""Secondary Tk panels. Slow operations stay outside the Tk event thread."""
from __future__ import annotations

import json
import threading
import tkinter as tk
import webbrowser
from pathlib import Path
from tkinter import filedialog, messagebox, ttk
from tkinter.scrolledtext import ScrolledText

from .art_policy import load_art_policy
from .art_studio import ArtStudio
from .config import REPO_ROOT, SCENARIOS, save_settings
from .repo_agent_tools import AutopilotError
from .workspaces import apply_workspace, branches, workspace_changes


def background(panel, operation, done):
    def work():
        try:
            value = operation()
            panel.messages.put(('callback', lambda: done(value)))
        except Exception as exc:
            message = str(exc)
            panel.messages.put(('callback', lambda: messagebox.showerror('Autopilot', message, parent=panel.window)))
    threading.Thread(target=work, daemon=True).start()


def project_dialog(panel):
    window = tk.Toplevel(panel.window)
    window.title('Projekt i wersja gry')
    frame = ttk.Frame(window, padding=20)
    frame.pack(fill='both', expand=True)
    ttk.Label(frame, text=str(REPO_ROOT), wraplength=750).pack(anchor='w')
    isolated = tk.BooleanVar(value=panel.settings.isolated_workspace)
    local = tk.BooleanVar(value=panel.settings.include_local_changes)
    branch = tk.StringVar(value=panel.settings.branch)
    journeys = tk.BooleanVar(value=panel.settings.gameplay_journeys)
    ttk.Checkbutton(frame, text='Wykonuj zadania w osobnej kopii gry', variable=isolated).pack(anchor='w', pady=8)
    ttk.Label(frame, text='Branch (puste pole oznacza bieżący HEAD):').pack(anchor='w')
    combo = ttk.Combobox(frame, textvariable=branch, width=70)
    combo.pack(fill='x', pady=6)
    ttk.Checkbutton(frame, text='Dołącz niezacommitowane pliki bieżącej wersji', variable=local).pack(anchor='w')
    ttk.Checkbutton(frame, text='Sprawdzaj zakup, ekwipunek, walkę i zapis', variable=journeys).pack(anchor='w')
    info = tk.StringVar(value='Pobranie aktualizacji odświeża listę branchy; nie przełącza otwartej gry.')
    ttk.Label(frame, textvariable=info, wraplength=750).pack(anchor='w', pady=10)
    def load(fetch):
        info.set('Sprawdzanie branchy…')
        background(panel, lambda: branches(REPO_ROOT, fetch), lambda values: (combo.configure(values=[''] + values), info.set('Lista branchy gotowa.')))
    def save():
        if branch.get().strip() and not isolated.get():
            info.set('Wybór brancha wymaga zaznaczenia osobnej kopii.')
            return
        panel.settings.branch = branch.get().strip()
        panel.settings.isolated_workspace = isolated.get()
        panel.settings.include_local_changes = local.get()
        panel.settings.gameplay_journeys = journeys.get()
        panel.settings.validate()
        save_settings(panel.settings)
        panel._refresh_project()
        window.destroy()
    ttk.Button(frame, text='Sprawdź aktualizacje z GitHuba', command=lambda: load(True)).pack(side='left')
    ttk.Button(frame, text='Zapisz wybór', command=save).pack(side='right')
    load(False)


def issues_dialog(panel):
    window = tk.Toplevel(panel.window)
    window.title('Usterki i historia ocen')
    window.geometry('1000x600')
    path = panel.output / 'issues.json'
    issues = json.loads(path.read_text(encoding='utf-8'))['issues'] if path.exists() else []
    tree = ttk.Treeview(window, columns=('id', 'status', 'title'), show='headings')
    labels = {'open': 'Otwarty', 'fixed': 'Naprawiony', 'returned': 'Powrócił', 'unverified': 'Do ponownej weryfikacji'}
    for key, label, width in [('id', 'Numer', 110), ('status', 'Stan', 180), ('title', 'Problem', 680)]:
        tree.heading(key, text=label)
        tree.column(key, width=width)
    tree.pack(fill='both', expand=True, padx=15, pady=15)
    details = ScrolledText(window, height=10, wrap='word')
    details.pack(fill='x', padx=15, pady=(0, 15))
    for i, issue in enumerate(issues):
        tree.insert('', 'end', iid=str(i), values=(issue['id'], labels[issue['status']], issue['title']))
    def select(_):
        if tree.selection():
            issue = issues[int(tree.selection()[0])]
            details.delete('1.0', 'end')
            details.insert('1.0', issue['recommendation'] + '\nDowody: ' + '\n'.join(issue['evidence'])
                + '\n\nHistoria:\n' + '\n'.join(f"{h['run']} / cykl {h['cycle']}: {labels[h['status']]}" for h in issue['history']))
    tree.bind('<<TreeviewSelect>>', select)
    if not issues:
        details.insert('1.0', 'Rejestr zostanie uzupełniony po pierwszym audycie w wersji 3.0.')


def apply_dialog(panel):
    job = panel._selected()
    if not job or not job.get('directory'):
        panel.status.set('Wybierz zadanie wykonane w osobnej kopii.')
        return
    state = json.loads((Path(job['directory']) / 'state.json').read_text(encoding='utf-8'))
    metadata = state.get('workspace')
    if not metadata:
        panel.status.set('To zadanie pracowało bezpośrednio w głównej grze.')
        return
    window = tk.Toplevel(panel.window)
    window.title('Przenieś sprawdzone zmiany do głównej gry')
    window.geometry('850x500')
    text = ScrolledText(window, wrap='word')
    text.pack(fill='both', expand=True, padx=15, pady=15)
    changes = workspace_changes(metadata)
    text.insert('1.0', 'Kopia: ' + metadata['root'] + '\nWynik: ' + state['status'] + '\n\nPliki:\n' + '\n'.join(changes))
    text.configure(state='disabled')
    def apply():
        from .runner import ProjectLock
        def operation():
            with ProjectLock(panel.output / 'run.lock'):
                return apply_workspace(metadata, panel.output, state.get('source_snapshot', {}))
        background(panel, operation, lambda result: (panel.status.set(f"Przeniesiono {len(result['applied'])} plików. Kopia: {result['backup']}"), window.destroy()))
    ttk.Button(window, text='Zastosuj zmiany z zachowaniem kopii', command=apply,
               state='normal' if state['status'] == 'PASSED' and changes else 'disabled').pack(pady=(0, 15))


def art_dialog(panel):
    window = tk.Toplevel(panel.window)
    window.title('Studio grafik — warianty, scena, ocena Sola')
    window.geometry('1050x750')
    frame = ttk.Frame(window, padding=18)
    frame.pack(fill='both', expand=True)
    stop = threading.Event()
    studio = ArtStudio(REPO_ROOT, panel.output, panel.settings,
        event=lambda message: panel.messages.put(('notice', message)), stop=stop)
    policy = load_art_policy(REPO_ROOT)
    target = tk.StringVar(value=policy['scenario_enemies']['combat_wolf'])
    region = tk.StringVar(value=policy['scenario_regions']['combat_wolf'])
    scenario = tk.StringVar(value='combat_wolf')
    count = tk.IntVar(value=1)
    for label, variable, values in [('Zmieniana grafika PNG', target, list(policy['scenario_enemies'].values())),
                                    ('Region', region, list(policy['region_references'])),
                                    ('Scena do podglądu', scenario, SCENARIOS)]:
        ttk.Label(frame, text=label).pack(anchor='w')
        ttk.Combobox(frame, textvariable=variable, values=values, width=90).pack(fill='x', pady=(0, 7))
    ttk.Label(frame, text='Opis wariantu:').pack(anchor='w')
    prompt = ScrolledText(frame, height=3, wrap='word')
    prompt.pack(fill='x')
    options = ttk.Frame(frame)
    options.pack(fill='x', pady=8)
    ttk.Label(options, text='Warianty (1–4):').pack(side='left')
    ttk.Spinbox(options, from_=1, to=4, textvariable=count, width=4).pack(side='left', padx=8)
    info = tk.StringVar(value='Nowe obrazy trafiają do podglądu. Oryginał jest zachowany.')
    ttk.Label(frame, textvariable=info, wraplength=950).pack(anchor='w', pady=8)
    tree = ttk.Treeview(frame, columns=('path', 'quality', 'status'), show='headings', height=6)
    for key, title in [('path', 'Wariant'), ('quality', 'Kontrola PNG'), ('status', 'Ocena')]:
        tree.heading(key, text=title)
    tree.pack(fill='both', expand=True)
    current = {'directory': None, 'busy': False}
    buttons = ttk.Frame(frame)
    buttons.pack(fill='x', pady=8)
    def refresh(value=None):
        current['busy'] = False
        tree.delete(*tree.get_children())
        if current['directory']:
            data = studio.read(current['directory'])
            for i, variant in enumerate(data['variants']):
                quality = 'OK' if variant['quality']['ok'] else '; '.join(variant['quality']['problems'])
                tree.insert('', 'end', iid=str(i), values=(variant['path'], quality, variant['review']['verdict'] if variant.get('review') else variant['status']))
        info.set('Gotowe. Wybierz wariant, aby obejrzeć go w grze i uruchomić ocenę Sola.')
    def request():
        if current['directory'] is None:
            current['directory'] = studio.request(target.get(), prompt.get('1.0', 'end').strip(), region.get(), scenario.get(), count.get())
        else:
            previous = studio.read(current['directory'])
            if (previous['target'], previous['prompt'], previous['region'], previous['scenario']) != (target.get(), prompt.get('1.0', 'end').strip(), region.get(), scenario.get()):
                raise AutopilotError('Opis zmienił się. Kliknij Nowe zlecenie, aby zachować poprzednie warianty.')
        return current['directory']
    def run(operation):
        if current['busy']:
            return
        stop.clear()
        current['busy'] = True
        info.set('Praca w toku — postęp w dzienniku głównego panelu.')
        def execute():
            try:
                return operation()
            finally:
                panel.messages.put(('callback', lambda: current.update(busy=False)))
        background(panel, execute, refresh)
    def selected():
        if not tree.selection():
            raise AutopilotError('Zaznacz wariant.')
        return int(tree.selection()[0])
    def generate():
        try:
            directory = request()
            run(lambda: studio.generate(directory))
        except Exception as exc:
            info.set(str(exc))
    def import_png():
        if current['busy']:
            return
        path = filedialog.askopenfilename(parent=window, filetypes=[('PNG', '*.png')])
        if path:
            try:
                studio.import_variant(request(), Path(path))
                refresh()
            except Exception as exc:
                info.set(str(exc))
    def preview():
        try:
            index = selected()
            run(lambda: studio.preview(current['directory'], index))
        except Exception as exc:
            info.set(str(exc))
    def report():
        try:
            variant = studio.read(current['directory'])['variants'][selected()]
            path = variant['preview_report'] or str(current['directory'] / variant['path'])
            webbrowser.open(Path(path).as_uri())
        except Exception as exc:
            info.set(str(exc))
    def install():
        if current['busy']:
            return
        try:
            from .runner import ProjectLock
            with ProjectLock(panel.output / 'run.lock'):
                path = studio.install(current['directory'], selected())
            refresh()
            info.set('Zastosowano: ' + str(path))
        except Exception as exc:
            info.set(str(exc))
    def history():
        if current['busy']:
            return
        path = filedialog.askopenfilename(parent=window, initialdir=studio.base, filetypes=[('Zlecenie grafik', 'request.json')])
        if path:
            try:
                directory = Path(path).parent
                data = studio.read(directory)
                current['directory'] = directory
                target.set(data['target']); region.set(data['region']); scenario.set(data['scenario'])
                prompt.delete('1.0', 'end'); prompt.insert('1.0', data['prompt'])
                refresh()
            except Exception as exc:
                info.set(str(exc))
    def fresh():
        if not current['busy']:
            current['directory'] = None
            tree.delete(*tree.get_children())
            info.set('Nowe zlecenie. Wpisz opis i wygeneruj lub importuj PNG.')
    for label, action in [('Nowe', fresh), ('Generuj PNG', generate), ('Importuj PNG', import_png), ('Podgląd + Sol', preview),
                          ('Otwórz wynik', report), ('Zastosuj wariant', install), ('Historia', history)]:
        ttk.Button(buttons, text=label, command=action).pack(side='left', padx=(0, 5))
    def catalog():
        dialog = tk.Toplevel(window)
        dialog.title('Zatwierdzone wzorce grafiki')
        text = ScrolledText(dialog, width=105, height=20)
        text.pack(fill='both', expand=True)
        for asset in studio.catalog():
            text.insert('end', f"{asset['kind']} · {asset['region']} · {asset['path']}\n")
        def add():
            path = filedialog.askopenfilename(parent=dialog, initialdir=REPO_ROOT / 'godot/assets', filetypes=[('PNG', '*.png')])
            if path:
                try:
                    relative = Path(path).resolve().relative_to(REPO_ROOT.resolve()).as_posix()
                    studio.approve_reference(relative, 'character', region.get())
                    text.insert('end', 'Zatwierdzono: ' + relative + '\n')
                except Exception as exc:
                    messagebox.showerror('Wzorzec', str(exc), parent=dialog)
        ttk.Button(dialog, text='Dodaj / ponownie zatwierdź wzorzec dla wybranego regionu', command=add).pack()
    ttk.Button(frame, text='Katalog zatwierdzonych wzorców', command=catalog).pack(anchor='w')
    ttk.Button(frame, text='Zatrzymaj pracę studia', command=stop.set).pack(anchor='e')
    def close():
        stop.set()
        window.destroy()
    window.protocol('WM_DELETE_WINDOW', close)
