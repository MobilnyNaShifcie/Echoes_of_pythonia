from __future__ import annotations

import copy
import json
import queue
import threading
import tkinter as tk
import uuid
import webbrowser
from dataclasses import asdict
from pathlib import Path
from tkinter import messagebox, ttk
from tkinter.scrolledtext import ScrolledText

try:
    from .config import OUTPUT_ROOT, REPO_ROOT, Settings, save_settings, write_json
    from .runner import ACTIVE, Autopilot
    from .repo_agent_tools import git_context
except ImportError:
    from config import OUTPUT_ROOT, REPO_ROOT, Settings, save_settings, write_json
    from runner import ACTIVE, Autopilot
    from repo_agent_tools import git_context

LABELS = {'QUEUED': 'W kolejce', 'STARTING': 'Uruchamianie', 'DEVELOPING': 'Astra: zmiany',
          'TESTING': 'Testy Godota', 'CAPTURING': 'Obrazy gry', 'REVIEWING': 'Sol: ocena',
          'PASSED': 'Zaliczone', 'NEEDS_CHANGES': 'Wymaga poprawek', 'BLOCKED': 'Zablokowane',
          'STOPPED': 'Zatrzymane', 'CAPTURED': 'Obrazy gotowe', 'TESTED': 'Testy zaliczone',
          'INTERRUPTED': 'Przerwane'}


def job_details(job, output):
    state = job
    directory = job.get('directory')
    if directory:
        path = Path(directory).resolve()
        if path.parent == output.resolve():
            try:
                state = json.loads((path / 'state.json').read_text(encoding='utf-8-sig'))
            except (OSError, ValueError):
                pass
    label = LABELS.get(state.get('status'), state.get('status', ''))
    origin = state.get('git_before', {})
    if state.get('phase'):
        label += f" · etap: {state['phase']} · ukończono: {len(state.get('completed_stages', []))}"
    if origin.get('branch'):
        label += f" [raport: {origin['branch']} · {origin.get('head', '')[:8]}]"
    error = state.get('error') or job.get('error')
    if error:
        return f'{label} — {error}\nWznów zaznaczone ponawia to zadanie na aktualnym projekcie. Szczegóły: Otwórz raport.'
    if state.get('status') == 'NEEDS_CHANGES':
        failures = [c['name'] for c in state.get('checks', []) if c.get('status') != 'PASS']
        summaries = [r.get('summary', '') for r in state.get('reviews', []) if r.get('verdict') != 'PASS']
        return label + ' — ' + '; '.join(failures + summaries) + '\nSzczegóły: Otwórz raport.'
    return label + (' — szczegóły: Otwórz raport.' if directory else '')


class Panel:
    def __init__(self, window, settings, output=OUTPUT_ROOT):
        self.window, self.settings, self.output = window, settings, output
        self.messages = queue.Queue()
        self.worker = None
        self.stop = threading.Event()
        self.auto_queue = False
        self.closing = False
        self.current = None
        self.queue_path = output / 'queue.json'
        self.jobs = []
        if self.queue_path.exists():
            try:
                self.jobs = json.loads(self.queue_path.read_text(encoding='utf-8'))
                for job in self.jobs:
                    if job['status'] in ACTIVE:
                        job['status'] = 'INTERRUPTED'
            except (OSError, ValueError, KeyError):
                # Preserve unreadable queue contents; do not silently overwrite them.
                messagebox.showerror('Kolejka', f'Nie można odczytać {self.queue_path}. Sprawdź plik przed kontynuacją.')
                raise
        known = {j.get('directory') for j in self.jobs}
        for state_file in sorted(output.glob('RUN-*/state.json')):
            if str(state_file.parent) in known:
                continue
            try:
                state = json.loads(state_file.read_text(encoding='utf-8'))
                if state['status'] in ACTIVE:
                    continue
                self.jobs.append({'id': uuid.uuid4().hex, 'task': state['task'],
                                  'mode': state['mode'], 'status': state['status'],
                                  'directory': str(state_file.parent),
                                  'settings': asdict(settings), 'resume': None})
            except (OSError, ValueError, KeyError):
                continue
        self._build()
        self._refresh()
        window.protocol('WM_DELETE_WINDOW', self._close)
        self._timer = window.after(150, self._poll)

    def _build(self):
        w = self.window
        w.title('Echoes Autopilot 3.0 — Astra + Sol')
        w.geometry('1240x930')
        w.minsize(1020, 750)
        w.configure(bg='#111722')
        style = ttk.Style(w)
        style.theme_use('clam')
        style.configure('.', font=('Segoe UI', 10), background='#111722', foreground='#e7edf8')
        style.configure('TButton', background='#28364b', padding=(12, 8), borderwidth=0)
        style.map('TButton', background=[('active', '#3e5472'), ('disabled', '#1c2431')])
        style.configure('TEntry', fieldbackground='#202b3b', foreground='#e7edf8')
        style.configure('Treeview', background='#192333', fieldbackground='#192333',
                        foreground='#e7edf8', rowheight=31, borderwidth=0)
        style.configure('Treeview.Heading', background='#28364b', foreground='#d2ddf0')
        style.map('Treeview', background=[('selected', '#3e5472')])
        main = ttk.Frame(w, padding=24)
        main.pack(fill='both', expand=True)
        ttk.Label(main, text='E C H O E S   /   A U T O P I L O T', foreground='#d7b67c').pack(anchor='w')
        ttk.Label(main, text='Twoje studio kontroli gry', font=('Segoe UI', 25, 'bold')).pack(anchor='w', pady=(6, 3))
        ttk.Label(main, text='Astra wprowadza zmiany  →  Godot uruchamia testy  →  Sol ocenia kod i wygląd',
                  foreground='#a4b4cd').pack(anchor='w', pady=(0, 18))
        self.project_info = tk.StringVar()
        self._refresh_project()
        ttk.Label(main, textvariable=self.project_info, foreground='#a4b4cd',
                  wraplength=1020).pack(anchor='w', pady=(0, 12))
        models = ttk.Frame(main)
        models.pack(fill='x')
        self.developer = tk.StringVar(value=self.settings.developer_model)
        self.reviewer = tk.StringVar(value=self.settings.reviewer_model)
        self.cycles = tk.StringVar(value=str(self.settings.max_cycles))
        for label, variable, width in [('Developer', self.developer, 23), ('Recenzent', self.reviewer, 23),
                                       ('Cykle', self.cycles, 4)]:
            ttk.Label(models, text=label).pack(side='left', padx=(0, 7))
            ttk.Entry(models, textvariable=variable, width=width).pack(side='left', padx=(0, 18))
        ttk.Label(main, text='Co zmienić w grze?', font=('Segoe UI', 12, 'bold')).pack(anchor='w', pady=(18, 6))
        self.task = ScrolledText(main, height=3, wrap='word', bg='#202b3b', fg='#e7edf8',
                                 insertbackground='white', relief='flat', font=('Segoe UI', 11), padx=10, pady=10)
        self.task.pack(fill='x')
        actions = ttk.Frame(main)
        actions.pack(fill='x', pady=10)
        for label, command in [('Dodaj zadanie', self._add), ('Uruchom kolejkę', self._start_queue),
                               ('Audyt Sola', lambda: self._enqueue('audit', 'Audyt błędów, rozgrywki i grafiki', True)),
                               ('Tylko testy', lambda: self._enqueue('test', 'Kontrole techniczne gry', True)),
                               ('Tylko obrazy', lambda: self._enqueue('capture', 'Zrzuty scen gry', True)),
                               ('Zatrzymaj', self._stop), ('Usuń z kolejki', self._remove_queued)]:
            ttk.Button(actions, text=label, command=command).pack(side='left', padx=(0, 6))
        self.status = tk.StringVar(value='Gotowe. Dodaj zadanie lub uruchom audyt bieżącej gry.')
        ttk.Label(main, textvariable=self.status, foreground='#d7b67c').pack(anchor='w', pady=(4, 8))
        self.tree = ttk.Treeview(main, columns=('task', 'mode', 'status'), show='headings', height=6)
        for column, label, width in [('task', 'Zadanie', 620), ('mode', 'Tryb', 85), ('status', 'Stan', 180)]:
            self.tree.heading(column, text=label)
            self.tree.column(column, width=width, stretch=column == 'task')
        self.tree.pack(fill='both', expand=True)
        self.tree.bind('<Double-1>', lambda _: self._report())
        self.tree.bind('<<TreeviewSelect>>', lambda _: self._show_details())
        footer = ttk.Frame(main)
        footer.pack(fill='x', pady=10)
        for label, command in [('Otwórz raport', self._report), ('Napraw i sprawdź', self._fix_findings), ('Wznów zaznaczone', self._resume),
                               ('Diagnostyka', self._doctor), ('Wszystkie raporty', self._history),
                               ('Zapisz ustawienia', self._settings), ('Instrukcja', self._help)]:
            ttk.Button(footer, text=label, command=command).pack(side='left', padx=(0, 6))
        extras = ttk.Frame(main)
        extras.pack(fill='x', pady=(0, 8))
        from .studio_panel import project_dialog, issues_dialog, art_dialog, apply_dialog
        for label, command in [('Projekt i branch', lambda: project_dialog(self)),
                               ('Usterki', lambda: issues_dialog(self)),
                               ('Studio grafik', lambda: art_dialog(self)),
                               ('Test czynności gracza', lambda: self._enqueue('journey', 'Zakup, ekwipunek, walka, zapis i odczyt', True)),
                               ('Zmiany z kopii', lambda: apply_dialog(self))]:
            ttk.Button(extras, text=label, command=command).pack(side='left', padx=(0, 6))
        self.details = ScrolledText(main, height=3, wrap='word', bg='#202b3b', fg='#f1c995',
                                   relief='flat', font=('Segoe UI', 10), state='disabled')
        self.details.pack(fill='x', pady=(0, 6))
        self.log = ScrolledText(main, height=5, wrap='word', bg='#0b111a', fg='#a8bbd8',
                                relief='flat', font=('Consolas', 9), state='disabled')
        self.log.pack(fill='x')
        ttk.Label(main, text='Lokalne raporty i kopie plików · Obrazy z rzeczywistego renderera · Limity i przerwanie pracy',
                  foreground='#8295b2').pack(anchor='w', pady=(10, 0))

    def _refresh_project(self):
        context = git_context(REPO_ROOT)
        self.project_info.set(f"Tryb: {'osobna kopia' if self.settings.isolated_workspace else 'bieżący katalog'} · wybrany branch: {self.settings.branch or 'bieżące pliki'}\nProjekt: {REPO_ROOT}\nBranch: {context['branch']} · commit: {context['head'][:12]} · lokalne zmiany: {'tak' if context['status'] else 'nie'}")

    def _settings(self):
        try:
            updated = copy.deepcopy(self.settings)
            updated.developer_model = self.developer.get().strip()
            updated.reviewer_model = self.reviewer.get().strip()
            updated.max_cycles = int(self.cycles.get())
            updated.validate()
            save_settings(updated)
            self.settings = updated
            self.status.set('Ustawienia zapisane.')
            return updated
        except (ValueError, OSError) as exc:
            messagebox.showerror('Ustawienia', str(exc))
            return None

    def _refresh(self):
        selected = self.tree.selection()
        self.tree.delete(*self.tree.get_children())
        for job in self.jobs:
            self.tree.insert('', 'end', iid=job['id'], values=(job['task'], job['mode'],
                                                            LABELS.get(job['status'], job['status'])))
        if selected and self.tree.exists(selected[0]):
            self.tree.selection_set(selected[0])
        elif self.jobs:
            self.tree.selection_set(self.jobs[-1]['id'])
            self.tree.see(self.jobs[-1]['id'])

    def _persist(self):
        write_json(self.queue_path, self.jobs)
        self._refresh()

    def _selected(self):
        selected = self.tree.selection()
        return next((j for j in self.jobs if selected and j['id'] == selected[0]), None)

    def _enqueue(self, mode, task, start=False, resume=None):
        settings = self._settings()
        if not settings:
            return
        job = {'id': uuid.uuid4().hex, 'task': task, 'mode': mode, 'status': 'QUEUED',
               'directory': '', 'settings': asdict(settings), 'resume': resume}
        self.jobs.append(job)
        self._persist()
        self.tree.selection_set(job['id'])
        self.tree.see(job['id'])
        if start and not self.worker:
            self.auto_queue = False
            self._next(job['id'])

    def _add(self):
        text = self.task.get('1.0', 'end').strip()
        if not text:
            self.status.set('Wpisz opis zmiany przed dodaniem zadania.')
            return
        self._enqueue('task', text)
        self.task.delete('1.0', 'end')

    def _start_queue(self):
        self.auto_queue = True
        if not self.worker:
            self._next()

    def _next(self, job_id=None):
        job = next((j for j in self.jobs if j['status'] == 'QUEUED'
                    and (job_id is None or j['id'] == job_id)), None)
        if not job:
            self.status.set('Kolejka zakończona.')
            return
        self._refresh_project()
        self.current = job
        self.stop = threading.Event()
        job['status'] = 'STARTING'
        self._persist()
        def work():
            try:
                runner = Autopilot(Settings(**job['settings']), stop=self.stop,
                                   on_event=lambda text: self.messages.put(('event', (text, str(runner.directory)))))
                directory = runner.run(job['task'], job['mode'], job.get('resume'))
                self.messages.put(('done', (str(directory), runner.state['status'], runner.state.get('error', ''))))
            except Exception as exc:
                self.messages.put(('failed', str(exc)))
        self.worker = threading.Thread(target=work, daemon=True)
        self.worker.start()

    def _stop(self):
        self.auto_queue = False
        self.stop.set()
        self.status.set('Zatrzymywanie aktywnego procesu…')

    def _append_log(self, message):
        self.log.configure(state='normal')
        self.log.insert('end', message + '\n')
        self.log.see('end')
        self.log.configure(state='disabled')

    def _poll(self):
        while not self.messages.empty():
            kind, value = self.messages.get_nowait()
            if kind == 'event':
                value, directory = value
                if self.current and directory != 'None':
                    self.current['directory'] = directory
                self._append_log(value)
                self.status.set(LABELS.get(value, value))
                if self.current and value in LABELS:
                    self.current['status'] = value
                    self._persist()
            elif kind in {'done', 'failed'}:
                if kind == 'done':
                    self.current['directory'], self.current['status'], self.current['error'] = value
                    self.status.set(LABELS.get(value[1], value[1]))
                else:
                    self.current['status'] = 'BLOCKED'
                    self.current['error'] = value
                    self._append_log(value)
                    self.status.set(value)
                self._persist()
                self.tree.selection_set(self.current['id'])
                self._show_details()
                self.worker = None
                # A failure pauses the queue so later tasks cannot compound an unresolved change.
                if self.current['status'] not in {'PASSED', 'CAPTURED', 'TESTED'}:
                    self.auto_queue = False
                if self.closing:
                    self.window.destroy()
                    return
                if self.auto_queue:
                    self._next()
            elif kind == 'callback':
                try:
                    value()
                except tk.TclError:
                    pass  # The owning dialog was closed while its operation completed.
            elif kind == 'notice':
                self._append_log(value)
            elif kind == 'doctor':
                self._append_log(value)
                self.status.set('Diagnostyka zakończona — wyniki w dzienniku.')
        self._timer = self.window.after(150, self._poll)

    def _show_details(self):
        job = self._selected()
        text = job_details(job, self.output) if job else 'Zaznacz zadanie, aby zobaczyć jego wynik.'
        self.details.configure(state='normal')
        self.details.delete('1.0', 'end')
        self.details.insert('1.0', text)
        self.details.configure(state='disabled')

    def _report(self):
        job = self._selected()
        if job and job.get('directory'):
            path = Path(job['directory']) / 'report.html'
            if path.exists():
                webbrowser.open(path.as_uri())
        else:
            self.status.set('Zaznacz zakończony przebieg z raportem.')

    def _resume(self):
        job = self._selected()
        if not job or not job.get('directory') or job['status'] not in {'BLOCKED', 'STOPPED', 'NEEDS_CHANGES', 'INTERRUPTED'}:
            self.status.set('Zaznacz przerwany przebieg lub przebieg wymagający poprawek.')
            return
        self._enqueue(job['mode'], job['task'], start=True, resume=job['directory'])

    def _fix_findings(self):
        job = self._selected()
        if job and job.get('mode') == 'task' and job.get('status') in {'BLOCKED', 'STOPPED', 'INTERRUPTED'}:
            self._resume()
            return
        if not job or not job.get('directory'):
            self.status.set('Najpierw zaznacz zakończony audyt Sola.')
            return
        directory = Path(job['directory']).resolve()
        if not directory.is_relative_to(self.output.resolve()):
            self.status.set('Raport musi znajdować się w katalogu tego projektu.')
            return
        try:
            state = json.loads((directory / 'state.json').read_text(encoding='utf-8'))
            findings = [f for r in state.get('reviews', []) for f in r.get('findings', []) if f['must_fix']]
        except (OSError, ValueError, KeyError) as exc:
            self.status.set(str(exc))
            return
        if not findings:
            self.status.set('Sol nie wskazał wymaganych napraw w tym raporcie.')
            return
        notes = '\n'.join(f"- {f['title']}: {f['recommendation']} Dowód: {'; '.join(f['evidence'])}" for f in findings)
        self._enqueue('task', 'Zweryfikuj i popraw problemy wskazane przez Sola w audycie. '
                      'Zachowaj zakres tych ustaleń, po naprawie ponownie sprawdź grę.\n'
                      + notes + '\nRaport źródłowy: ' + str(directory / 'report.html'), start=True)
        if self.worker and self.current != self.jobs[-1]:
            self.status.set('Naprawa czeka w kolejce; trwa poprzednie zadanie.')

    def _remove_queued(self):
        job = self._selected()
        if job and job['status'] == 'QUEUED':
            self.jobs.remove(job)
            self._persist()
        else:
            self.status.set('Można usunąć tylko zadanie oczekujące w kolejce.')

    def _doctor(self):
        settings = copy.deepcopy(self.settings)
        def work():
            try:
                checks = Autopilot(settings).doctor()
                message = '\n'.join(('OK' if c['ok'] else 'BRAK') + ' · ' + c['name'] + ': ' + c['detail'] for c in checks)
            except Exception as exc:
                message = str(exc)
            self.messages.put(('doctor', message))
        threading.Thread(target=work, daemon=True).start()

    def _history(self):
        self.output.mkdir(parents=True, exist_ok=True)
        import os
        os.startfile(self.output)

    def _help(self):
        window = tk.Toplevel(self.window)
        window.title('Echoes Autopilot — instrukcja')
        window.geometry('900x650')
        text = ScrolledText(window, wrap='word', font=('Segoe UI', 11), padx=18, pady=18)
        text.pack(fill='both', expand=True)
        text.insert('1.0', (REPO_ROOT / 'tools/echoes_autopilot_desktop/README_AUTOPILOT.md').read_text(encoding='utf-8-sig'))
        text.configure(state='disabled')

    def _close(self):
        if self.worker:
            self.closing = True
            self._stop()
        else:
            self.window.after_cancel(self._timer)
            self.window.destroy()


def launch(settings):
    window = tk.Tk()
    Panel(window, settings)
    def ready():
        import os
        window.deiconify()
        window.lift()
        window.update_idletasks()
        write_json(OUTPUT_ROOT / 'panel-ready.json', {'pid': os.getpid(), 'visible': bool(window.winfo_viewable())})
    window.after(300, ready)
    window.mainloop()
