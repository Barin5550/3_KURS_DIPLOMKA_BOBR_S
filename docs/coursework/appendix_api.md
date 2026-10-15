<!-- Текст перед листингом приложения К; вставляется tool/coursework/build_coursework.py. -->

Все адреса, кроме проверки связи, каталога, регистрации и входа, требуют заголовок `Authorization: Bearer <токен>`. Тела запросов и ответов передаются в формате JSON.

Таблица К.1 — Адреса API сервера

| Метод | Адрес | Назначение |
|---|---|---|
| GET | `/api/health` | Проверка связи |
| GET | `/api/directions` | Каталог направлений и тем |
| POST | `/api/auth/register` | Регистрация |
| POST | `/api/auth/login` | Вход, выдача токена |
| POST | `/api/auth/logout` | Выход, удаление токена |
| GET | `/api/me` | Данные своего профиля |
| PUT | `/api/me` | Изменение имени, email и цвета аватара |
| PUT | `/api/me/password` | Смена пароля |
| PUT | `/api/me/reminder` | Время ежедневного напоминания |
| DELETE | `/api/me` | Удаление аккаунта со всеми данными |
| GET | `/api/plans` | Список планов |
| POST | `/api/plans` | Сохранение нового плана |
| GET | `/api/plans/active` | Активный план |
| GET | `/api/plans/{id}` | Один план |
| PATCH | `/api/plans/{id}` | Переименование плана |
| DELETE | `/api/plans/{id}` | Удаление плана с темами и занятиями |
| POST | `/api/plans/{id}/activate` | Сделать план активным |
| PUT | `/api/plans/{id}/settings` | Новые настройки расписания |
| GET | `/api/plans/{id}/topics` | Темы плана по порядку |
| PUT | `/api/plans/{id}/topics` | Новый список тем плана |
| GET | `/api/plans/{id}/sessions` | Занятия плана |
| PUT | `/api/plans/{id}/sessions/open` | Новое расписание невыполненных занятий |
| GET | `/api/sessions/completed` | Выполненные занятия |
| GET | `/api/sessions/{id}` | Одно занятие |
| PUT | `/api/sessions/{id}/done` | Отметка о выполнении |
| GET | `/api/custom-topics` | Свои темы |
| POST | `/api/custom-topics` | Новая своя тема |
| GET | `/api/custom-topics/{id}` | Одна своя тема |
| PUT | `/api/custom-topics/{id}` | Изменение своей темы |
| DELETE | `/api/custom-topics/{id}` | Удаление своей темы |
| GET | `/api/favorites` | Избранные темы |
| POST | `/api/favorites/{id}/toggle` | Добавить в избранное или убрать |
| GET | `/api/notes` | Заметки (все или к одной теме) |
| POST | `/api/notes` | Новая заметка |
| GET | `/api/notes/{id}` | Одна заметка |
| PUT | `/api/notes/{id}` | Изменение заметки |
| DELETE | `/api/notes/{id}` | Удаление заметки |
| GET | `/api/pomodoros` | Журнал Pomodoro |
| POST | `/api/pomodoros` | Запись завершённого интервала |
