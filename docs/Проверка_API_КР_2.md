# ПРОВЕРКА РАБОТЫ С ДАННЫМИ ЧЕРЕЗ API

Проверка выполнена 04.11.2026 на компьютере с Linux. Сервер запущен из папки проекта командой
`dart run bin/marshrut_server.dart --port 18093 --db <временный файл>`, то есть с новой пустой базой.
Запросы отправлялись программой curl по адресу `http://localhost:18093`. Использовались только
тестовые пользователи (test.student@example.com и anna.test@example.com), настоящих данных нет.
Токен входа в журнале заменён на `<токен>`.

Итог: 37 запросов, все ответы совпали с ожидаемыми. Заметки и свои темы проверены полностью:
добавление (201), получение (200), изменение (204), удаление (204). Ошибки: неверные данные — 400,
нет токена, неверный или устаревший токен — 401, запись не найдена или чужая — 404.

Таблица 1 — Сводка запросов

| № | Запрос | Что проверялось | Ответ |
|--|----------|--------------------|---|
| 1 | `GET /api/health` | Проверка связи | 200 |
| 2 | `POST /api/auth/register` | Регистрация тестового пользователя | 201 |
| 3 | `POST /api/auth/register` | Повторная регистрация с тем же email — ошибка 400 | 400 |
| 4 | `POST /api/auth/login` | Вход с неверным паролем — ошибка | 400 |
| 5 | `POST /api/auth/login` | Вход: сервер выдаёт токен | 200 |
| 6 | `GET /api/notes` | Список заметок без токена — ошибка 401 | 401 |
| 7 | `GET /api/notes` | Список заметок с неверным токеном — ошибка 401 | 401 |
| 8 | `GET /api/me` | Профиль (получение данных с токеном) | 200 |
| 9 | `POST /api/notes` | Добавление заметки | 201 |
| 10 | `GET /api/notes` | Получение списка заметок | 200 |
| 11 | `GET /api/notes/1` | Получение одной заметки | 200 |
| 12 | `PUT /api/notes/1` | Изменение заметки | 204 |
| 13 | `GET /api/notes/1` | Заметка после изменения | 200 |
| 14 | `POST /api/notes` | Добавление заметки без заголовка — ошибка 400 | 400 |
| 15 | `POST /api/notes` | Тело запроса не JSON — ошибка 400 | 400 |
| 16 | `DELETE /api/notes/1` | Удаление заметки | 204 |
| 17 | `GET /api/notes/1` | Получение удалённой заметки — ошибка 404 | 404 |
| 18 | `PUT /api/notes/1` | Изменение удалённой заметки — ошибка 404 | 404 |
| 19 | `DELETE /api/notes/1` | Повторное удаление — ошибка 404 | 404 |
| 20 | `GET /api/notes/999999` | Несуществующая заметка — ошибка 404 | 404 |
| 21 | `GET /api/nesushchestvuet` | Несуществующий адрес — ошибка 404 | 404 |
| 22 | `POST /api/custom-topics` | Своя тема с длительностью 20 минут (меньше 30) — ошибка 400 | 400 |
| 23 | `POST /api/custom-topics` | Добавление своей темы | 201 |
| 24 | `GET /api/custom-topics` | Получение списка своих тем | 200 |
| 25 | `PUT /api/custom-topics/custom_1` | Изменение своей темы | 204 |
| 26 | `GET /api/custom-topics/custom_1` | Своя тема после изменения | 200 |
| 27 | `DELETE /api/custom-topics/custom_1` | Удаление своей темы | 204 |
| 28 | `GET /api/custom-topics/custom_1` | Получение удалённой темы — ошибка 404 | 404 |
| 29 | `POST /api/auth/logout` | Выход: токен удаляется на сервере | 204 |
| 30 | `GET /api/me` | Запрос со старым токеном после выхода — ошибка 401 | 401 |
| 31 | `POST /api/auth/register` | Регистрация второго тестового пользователя (А) | 201 |
| 32 | `POST /api/auth/login` | Вход пользователя А | 200 |
| 33 | `POST /api/notes` | Пользователь А добавляет заметку | 201 |
| 34 | `POST /api/auth/login` | Вход первого тестового пользователя (Б) | 200 |
| 35 | `GET /api/notes/2` | Пользователь Б запрашивает заметку пользователя А — ошибка 404 | 404 |
| 36 | `DELETE /api/notes/2` | Пользователь Б пытается удалить заметку пользователя А — ошибка 404 | 404 |
| 37 | `GET /api/notes` | Список заметок пользователя Б — чужой заметки в нём нет | 200 |

## Запросы и ответы полностью

### 1. Проверка связи
```
GET /api/health

Ответ 200:
{"status":"ok","service":"Маршрут","version":1}
```

### 2. Регистрация тестового пользователя
```
POST /api/auth/register
Content-Type: application/json

{"name":"Тест Студент","email":"test.student@example.com","password":"Parol2026"}

Ответ 201:
{"id":1,"name":"Тест Студент","email":"test.student@example.com","avatarColor":4282211070,"createdAt":"2026-11-04T05:44:05.000","reminderEnabled":false,"reminderHour":19,"reminderMinute":0}
```

### 3. Повторная регистрация с тем же email — ошибка 400
```
POST /api/auth/register
Content-Type: application/json

{"name":"Тест Студент","email":"test.student@example.com","password":"Parol2026"}

Ответ 400:
{"error":"Пользователь с таким email уже существует"}
```

### 4. Вход с неверным паролем — ошибка
```
POST /api/auth/login
Content-Type: application/json

{"email":"test.student@example.com","password":"Neverno123"}

Ответ 400:
{"error":"Неверный email или пароль"}
```

### 5. Вход: сервер выдаёт токен
```
POST /api/auth/login
Content-Type: application/json

{"email":"test.student@example.com","password":"Parol2026"}

Ответ 200:
{"token":"<токен>","user":{"id":1,"name":"Тест Студент","email":"test.student@example.com","avatarColor":4282211070,"createdAt":"2026-11-04T05:44:05.000","reminderEnabled":false,"reminderHour":19,"reminderMinute":0}}
```

### 6. Список заметок без токена — ошибка 401
```
GET /api/notes

Ответ 401:
{"error":"Требуется вход в аккаунт"}
```

### 7. Список заметок с неверным токеном — ошибка 401
```
GET /api/notes
Authorization: Bearer неверный-токен-123

Ответ 401:
{"error":"Сессия истекла, войдите снова"}
```

### 8. Профиль (получение данных с токеном)
```
GET /api/me
Authorization: Bearer <токен>

Ответ 200:
{"id":1,"name":"Тест Студент","email":"test.student@example.com","avatarColor":4282211070,"createdAt":"2026-11-04T05:44:05.000","reminderEnabled":false,"reminderHour":19,"reminderMinute":0}
```

### 9. Добавление заметки
```
POST /api/notes
Authorization: Bearer <токен>
Content-Type: application/json

{"title":"Списки в Python","body":"append добавляет в конец","topicId":"py_lists"}

Ответ 201:
{"id":1}
```

### 10. Получение списка заметок
```
GET /api/notes
Authorization: Bearer <токен>

Ответ 200:
[{"id":1,"userId":1,"title":"Списки в Python","body":"append добавляет в конец","topicId":"py_lists","topicTitle":null,"createdAt":"2026-11-04T05:44:05.000","updatedAt":"2026-11-04T05:44:05.000"}]
```

### 11. Получение одной заметки
```
GET /api/notes/1
Authorization: Bearer <токен>

Ответ 200:
{"id":1,"userId":1,"title":"Списки в Python","body":"append добавляет в конец","topicId":"py_lists","topicTitle":null,"createdAt":"2026-11-04T05:44:05.000","updatedAt":"2026-11-04T05:44:05.000"}
```

### 12. Изменение заметки
```
PUT /api/notes/1
Authorization: Bearer <токен>
Content-Type: application/json

{"title":"Списки в Python","body":"append добавляет в конец, insert — по индексу"}

Ответ 204:
(пустое тело)
```

### 13. Заметка после изменения
```
GET /api/notes/1
Authorization: Bearer <токен>

Ответ 200:
{"id":1,"userId":1,"title":"Списки в Python","body":"append добавляет в конец, insert — по индексу","topicId":"py_lists","topicTitle":null,"createdAt":"2026-11-04T05:44:05.000","updatedAt":"2026-11-04T05:44:05.000"}
```

### 14. Добавление заметки без заголовка — ошибка 400
```
POST /api/notes
Authorization: Bearer <токен>
Content-Type: application/json

{"body":"без заголовка"}

Ответ 400:
{"error":"Поле «title» не заполнено или имеет неверный тип"}
```

### 15. Тело запроса не JSON — ошибка 400
```
POST /api/notes
Authorization: Bearer <токен>
Content-Type: application/json

это не json

Ответ 400:
{"error":"Тело запроса должно быть объектом JSON"}
```

### 16. Удаление заметки
```
DELETE /api/notes/1
Authorization: Bearer <токен>

Ответ 204:
(пустое тело)
```

### 17. Получение удалённой заметки — ошибка 404
```
GET /api/notes/1
Authorization: Bearer <токен>

Ответ 404:
{"error":"Заметка не найдена"}
```

### 18. Изменение удалённой заметки — ошибка 404
```
PUT /api/notes/1
Authorization: Bearer <токен>
Content-Type: application/json

{"title":"x","body":"y"}

Ответ 404:
{"error":"Заметка не найдена"}
```

### 19. Повторное удаление — ошибка 404
```
DELETE /api/notes/1
Authorization: Bearer <токен>

Ответ 404:
{"error":"Заметка не найдена"}
```

### 20. Несуществующая заметка — ошибка 404
```
GET /api/notes/999999
Authorization: Bearer <токен>

Ответ 404:
{"error":"Заметка не найдена"}
```

### 21. Несуществующий адрес — ошибка 404
```
GET /api/nesushchestvuet
Authorization: Bearer <токен>

Ответ 404:
{"error":"Адрес не найден"}
```

### 22. Своя тема с длительностью 20 минут (меньше 30) — ошибка 400
```
POST /api/custom-topics
Authorization: Bearer <токен>
Content-Type: application/json

{"directionId":"python","title":"Своя тема","category":"Практика","minutes":20}

Ответ 400:
{"error":"От 0,5 до 100 часов"}
```

### 23. Добавление своей темы
```
POST /api/custom-topics
Authorization: Bearer <токен>
Content-Type: application/json

{"directionId":"python","title":"Работа с файлами","description":"open, with, чтение и запись","category":"Практика","minutes":90}

Ответ 201:
{"id":"custom_1"}
```

### 24. Получение списка своих тем
```
GET /api/custom-topics
Authorization: Bearer <токен>

Ответ 200:
[{"id":"custom_1","title":"Работа с файлами","description":"open, with, чтение и запись","minutes":90,"level":3,"category":"Практика","prerequisites":[],"isCustom":true}]
```

### 25. Изменение своей темы
```
PUT /api/custom-topics/custom_1
Authorization: Bearer <токен>
Content-Type: application/json

{"title":"Работа с файлами и папками","description":"open, with, os.listdir","category":"Практика","minutes":120}

Ответ 204:
(пустое тело)
```

### 26. Своя тема после изменения
```
GET /api/custom-topics/custom_1
Authorization: Bearer <токен>

Ответ 200:
{"id":"custom_1","title":"Работа с файлами и папками","description":"open, with, os.listdir","minutes":120,"level":3,"category":"Практика","prerequisites":[],"isCustom":true,"directionId":"python"}
```

### 27. Удаление своей темы
```
DELETE /api/custom-topics/custom_1
Authorization: Bearer <токен>

Ответ 204:
(пустое тело)
```

### 28. Получение удалённой темы — ошибка 404
```
GET /api/custom-topics/custom_1
Authorization: Bearer <токен>

Ответ 404:
{"error":"Тема не найдена"}
```

### 29. Выход: токен удаляется на сервере
```
POST /api/auth/logout
Authorization: Bearer <токен>

Ответ 204:
(пустое тело)
```

### 30. Запрос со старым токеном после выхода — ошибка 401
```
GET /api/me
Authorization: Bearer <токен>

Ответ 401:
{"error":"Сессия истекла, войдите снова"}
```

### 31. Регистрация второго тестового пользователя (А)
```
POST /api/auth/register
Content-Type: application/json

{"name":"Пользователь Анна","email":"anna.test@example.com","password":"Anna2026x"}

Ответ 201:
{"id":2,"name":"Пользователь Анна","email":"anna.test@example.com","avatarColor":4281236786,"createdAt":"2026-11-04T05:44:17.000","reminderEnabled":false,"reminderHour":19,"reminderMinute":0}
```

### 32. Вход пользователя А
```
POST /api/auth/login
Content-Type: application/json

{"email":"anna.test@example.com","password":"Anna2026x"}

Ответ 200:
{"token":"<токен>","user":{"id":2,"name":"Пользователь Анна","email":"anna.test@example.com","avatarColor":4281236786,"createdAt":"2026-11-04T05:44:17.000","reminderEnabled":false,"reminderHour":19,"reminderMinute":0}}
```

### 33. Пользователь А добавляет заметку
```
POST /api/notes
Authorization: Bearer <токен>
Content-Type: application/json

{"title":"Заметка Анны","body":"личная"}

Ответ 201:
{"id":2}
```

### 34. Вход первого тестового пользователя (Б)
```
POST /api/auth/login
Content-Type: application/json

{"email":"test.student@example.com","password":"Parol2026"}

Ответ 200:
{"token":"<токен>","user":{"id":1,"name":"Тест Студент","email":"test.student@example.com","avatarColor":4282211070,"createdAt":"2026-11-04T05:44:05.000","reminderEnabled":false,"reminderHour":19,"reminderMinute":0}}
```

### 35. Пользователь Б запрашивает заметку пользователя А — ошибка 404
```
GET /api/notes/2
Authorization: Bearer <токен>

Ответ 404:
{"error":"Заметка не найдена"}
```

### 36. Пользователь Б пытается удалить заметку пользователя А — ошибка 404
```
DELETE /api/notes/2
Authorization: Bearer <токен>

Ответ 404:
{"error":"Заметка не найдена"}
```

### 37. Список заметок пользователя Б — чужой заметки в нём нет
```
GET /api/notes
Authorization: Bearer <токен>

Ответ 200:
[]
```

## Журнал в окне сервера

Так выглядит журнал, который сервер печатает в своём окне: время, метод, адрес, код ответа и время обработки. Первые две строки — проверка связи перед началом.

```
Журнал запросов:
05:44:04  GET    /api/health  →  200  (4 мс)
05:44:04  GET    /api/health  →  200  (0 мс)
05:44:05  POST   /api/auth/register  →  201  (300 мс)
05:44:05  POST   /api/auth/register  →  400  (1 мс)
05:44:05  POST   /api/auth/login  →  400  (215 мс)
05:44:05  POST   /api/auth/login  →  200  (211 мс)
05:44:05  GET    /api/notes  →  401  (0 мс)
05:44:05  GET    /api/notes  →  401  (1 мс)
05:44:05  GET    /api/me  →  200  (1 мс)
05:44:05  POST   /api/notes  →  201  (2 мс)
05:44:05  GET    /api/notes  →  200  (5 мс)
05:44:05  GET    /api/notes/1  →  200  (1 мс)
05:44:05  PUT    /api/notes/1  →  204  (2 мс)
05:44:05  GET    /api/notes/1  →  200  (0 мс)
05:44:05  POST   /api/notes  →  400  (0 мс)
05:44:05  POST   /api/notes  →  400  (1 мс)
05:44:05  DELETE /api/notes/1  →  204  (1 мс)
05:44:05  GET    /api/notes/1  →  404  (0 мс)
05:44:05  PUT    /api/notes/1  →  404  (0 мс)
05:44:05  DELETE /api/notes/1  →  404  (0 мс)
05:44:05  GET    /api/notes/999999  →  404  (0 мс)
05:44:05  GET    /api/nesushchestvuet  →  404  (0 мс)
05:44:05  POST   /api/custom-topics  →  400  (1 мс)
05:44:05  POST   /api/custom-topics  →  201  (2 мс)
05:44:05  GET    /api/custom-topics  →  200  (2 мс)
05:44:05  PUT    /api/custom-topics/custom_1  →  204  (2 мс)
05:44:05  GET    /api/custom-topics/custom_1  →  200  (1 мс)
05:44:05  DELETE /api/custom-topics/custom_1  →  204  (3 мс)
05:44:06  GET    /api/custom-topics/custom_1  →  404  (0 мс)
05:44:06  POST   /api/auth/logout  →  204  (0 мс)
05:44:06  GET    /api/me  →  401  (0 мс)
05:44:17  POST   /api/auth/register  →  201  (285 мс)
05:44:17  POST   /api/auth/login  →  200  (246 мс)
05:44:17  POST   /api/notes  →  201  (1 мс)
05:44:17  POST   /api/auth/login  →  200  (221 мс)
05:44:17  GET    /api/notes/2  →  404  (1 мс)
05:44:17  DELETE /api/notes/2  →  404  (1 мс)
05:44:17  GET    /api/notes  →  200  (0 мс)
```
