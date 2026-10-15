// Генератор презентаций «Маршрут»: итоговая защита и защита концепции.
const pptxgen = require("pptxgenjs");
const path = require("path");
const { applyTheme } = require(process.env.SKILL_DIR + "/scripts/apply_theme.js");

const IMG = path.join(__dirname, "img");
const OUT = process.argv[2] || __dirname;

const THEME = {
  name: "Маршрут",
  headFontFace: "Calibri",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "0F1D3D", lt1: "FFFFFF", dk2: "1A3A8F", lt2: "EEF2FB",
    accent1: "F57C00", accent2: "1A3A8F", accent3: "2E9D5B", accent4: "FFA040",
    accent5: "9DB4FF", accent6: "5A6B8C", hlink: "1A3A8F", folHlink: "5A6B8C",
  },
};
const HEX = THEME.colors;
const PHONE_RATIO = 572 / 1202;
const AUTHOR = "Баринов Николай Владимирович";
const GROUP = "ПО2410";
const SUPERVISOR = "Синтиков Еркебулан Канатович";
const COLLEGE = "Колледж Astana IT University";
const CITY_YEAR = "Астана 2026";

function newDeck(title) {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5
  pres.title = title;
  pres.author = AUTHOR;
  pres.company = "Группа " + GROUP;
  pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
  const C = pres.SchemeColor;

  pres.defineSlideMaster({
    title: "DARK",
    background: { color: C.text1 },
    objects: [],
  });
  pres.defineSlideMaster({
    title: "LIGHT",
    background: { color: C.background1 },
    margin: [0.4, 0.6, 0.6, 0.6],
    objects: [
      { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.35, w: 12.1, h: 0.8,
        fontSize: 32, bold: true, color: C.text2, valign: "middle", align: "left", margin: 0 }, text: "" } },
      { text: { text: "«Маршрут» · " + AUTHOR + " · " + GROUP, options: {
        x: 0.6, y: 6.98, w: 9, h: 0.3, fontSize: 10, color: C.accent6, margin: 0 } } },
    ],
    slideNumber: { x: 12.23, y: 6.98, w: 0.5, h: 0.3, fontSize: 10, color: C.accent6, align: "right" },
  });
  return { pres, C };
}

// ---------- helpers ----------
function T(slide, text, o) { slide.addText(text, Object.assign({ isTextBox: true, margin: 0, valign: "top" }, o)); }

function phone(slide, name, x, y, h, caption, C) {
  const w = h * PHONE_RATIO;
  slide.addImage({ path: path.join(IMG, name + ".png"), x, y, w, h, objectName: "Скриншот " + name,
    altText: caption || name });
  if (caption) T(slide, caption, { x: x - 0.2, y: y + h + 0.1, w: w + 0.4, h: 0.35, fontSize: 12,
    color: C.accent6, align: "center" });
  return w;
}

function circle(slide, pres, C, n, x, y, d, fill) {
  slide.addText(String(n), { shape: pres.shapes.OVAL, x, y, w: d, h: d, fill: { color: fill || C.accent1 },
    color: C.background1, fontSize: d > 0.5 ? 18 : 13, bold: true, align: "center", valign: "middle", margin: 0,
    objectName: "Номер " + n });
}

function card(slide, pres, C, x, y, w, h, fill, name) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.12, fill: { color: fill || C.background2 },
    line: { type: "none" }, objectName: name || "Карточка" });
}

function chip(slide, pres, C, text, x, y, w, h, fill, color, fs) {
  slide.addText(text, { shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.2, x, y, w, h,
    fill: { color: fill || C.background2 }, line: { type: "none" }, color: color || C.text2, fontSize: fs || 13,
    bold: true, align: "center", valign: "middle", margin: 0.05, objectName: "Метка " + text });
}

function light(pres, title, section) {
  const s = pres.addSlide({ masterName: "LIGHT", sectionTitle: section });
  s.addText(title, { placeholder: "title" });
  return s;
}

// ---------- общие слайды ----------
function slideTitle(pres, C, kind, section) {
  const s = pres.addSlide({ masterName: "DARK", sectionTitle: section });
  s.addImage({ path: path.join(IMG, "icon.png"), x: 0.7, y: 0.7, w: 1.0, h: 1.0, objectName: "Иконка приложения", altText: "Иконка «Маршрут»" });
  T(s, COLLEGE, { x: 1.95, y: 0.7, w: 5.8, h: 1.0, fontSize: 18, bold: true, color: C.background1, valign: "middle" });
  T(s, CITY_YEAR, { x: 0.7, y: 6.6, w: 7.4, h: 0.35, fontSize: 14, color: C.accent5 });
  T(s, kind.toUpperCase(), { x: 0.7, y: 2.0, w: 7.4, h: 0.4, fontSize: 14, bold: true, color: C.accent1, charSpacing: 2 });
  T(s, "Маршрут", { x: 0.7, y: 2.4, w: 7.4, h: 1.1, fontSize: 60, bold: true, color: C.background1, fontFace: THEME.headFontFace });
  T(s, "Приложение для автоматического формирования персонального плана обучения",
    { x: 0.7, y: 3.55, w: 7.0, h: 0.9, fontSize: 22, color: C.accent5 });
  T(s, "ПМ07. Разработка мобильных приложений · Flutter и Dart", { x: 0.7, y: 4.55, w: 7.4, h: 0.4, fontSize: 14, color: C.accent5 });
  T(s, [
    { text: "Выполнил: ", options: { color: C.accent5 } },
    { text: AUTHOR + ", группа " + GROUP, options: { color: C.background1, bold: true, breakLine: true } },
    { text: "Руководитель: ", options: { color: C.accent5 } },
    { text: SUPERVISOR, options: { color: C.background1, bold: true } },
  ], { x: 0.7, y: 5.55, w: 7.6, h: 0.8, fontSize: 15, paraSpaceAfter: 6 });
  phone(s, "05_home", 8.0, 0.75, 6.0, null, C);
  phone(s, "19_preview", 10.25, 1.4, 5.25, null, C);
  return s;
}

function slideProblem(pres, C, section) {
  const s = light(pres, "Проблема: учиться самому трудно без плана", section);
  const pains = [
    ["Неясен порядок тем", "Темы зависят друг от друга: виджеты Flutter не понять без основ Dart."],
    ["Не учтены знания и время", "Курсы дают один план для всех и свой темп, а не ваш."],
    ["План ломается при отставании", "Пропустил пару дней, и расписание теряет смысл. Человек бросает учёбу."],
  ];
  pains.forEach(([h, d], i) => {
    const y = 1.5 + i * 1.6;
    card(s, pres, C, 0.6, y, 6.6, 1.35, C.background2, "Проблема " + (i + 1));
    circle(s, pres, C, i + 1, 0.85, y + 0.33, 0.65);
    T(s, h, { x: 1.75, y: y + 0.2, w: 5.2, h: 0.4, fontSize: 18, bold: true, color: C.text2 });
    T(s, d, { x: 1.75, y: y + 0.62, w: 5.25, h: 0.65, fontSize: 14, color: C.text1 });
  });
  card(s, pres, C, 7.6, 1.5, 5.13, 4.55, C.text2, "Цель");
  T(s, "ЦЕЛЬ", { x: 7.95, y: 1.75, w: 4.5, h: 0.3, fontSize: 13, bold: true, color: C.accent4, charSpacing: 2 });
  T(s, "Приложение само строит план по дням с учётом знаний, времени и дедлайна и перестраивает его при отставании",
    { x: 7.95, y: 2.1, w: 4.5, h: 1.6, fontSize: 18, bold: true, color: C.background1 });
  T(s, "ЦЕЛЕВАЯ АУДИТОРИЯ", { x: 7.95, y: 3.85, w: 4.5, h: 0.3, fontSize: 13, bold: true, color: C.accent4, charSpacing: 2 });
  T(s, [
    { text: "Студенты колледжей и вузов", options: { bullet: true, breakLine: true } },
    { text: "Самоучки: программирование, языки", options: { bullet: true, breakLine: true } },
    { text: "Те, кто меняет профессию", options: { bullet: true } },
  ], { x: 7.95, y: 4.2, w: 4.5, h: 1.3, fontSize: 15, color: C.background1, paraSpaceAfter: 4 });
  const steps = ["Направление", "Тест", "Часы и дедлайн", "План по дням"];
  steps.forEach((t, i) => {
    chip(s, pres, C, t, 0.6 + i * 3.07, 6.3, 2.6, 0.45, i === 3 ? C.accent1 : C.background2, i === 3 ? C.background1 : C.text2, 14);
    if (i < 3) T(s, "→", { x: 3.22 + i * 3.07, y: 6.3, w: 0.4, h: 0.45, fontSize: 18, bold: true, color: C.accent1, align: "center", valign: "middle" });
  });
  s.addNotes("Здравствуйте. Моя тема — создание приложения для автоматического формирования персонального плана обучения. " +
    "Когда человек решает выучить, например, Flutter, он видит сотни статей и курсов, но не понимает, в каком порядке их проходить, сколько это займёт и успеет ли он к сроку. " +
    "Готовые курсы не учитывают, что вы уже знаете и сколько у вас времени. А стоит пропустить пару дней, и расписание теряет смысл. " +
    "Цель работы — приложение «Маршрут», которое само строит план по дням и перестраивает его при отставании. " +
    "Целевая аудитория — студенты, самоучки и люди, которые меняют профессию. Сценарий простой: выбрал направление, прошёл тест, указал часы и дедлайн и получил план.");
  return s;
}

function slideCompetitors(pres, C, section) {
  const s = light(pres, "Аналоги не строят персональный маршрут", section);
  const head = ["Возможность", "roadmap.sh", "Duolingo", "Stepik / Coursera", "Notion / Todoist", "Маршрут"];
  const rows = [
    ["Порядок тем по зависимостям", "статичная схема", "внутри курса", "внутри курса", "нет", "автоматически"],
    ["Учёт имеющихся знаний", "нет", "тест уровня", "нет", "нет", "диагностический тест"],
    ["План по дням под своё время", "нет", "ежедневная цель", "дедлайны курса", "вручную", "да"],
    ["Перестройка при отставании", "нет", "нет", "нет", "вручную", "одной кнопкой"],
    ["Где хранятся данные", "облако сервиса", "облако сервиса", "облако сервиса", "облако сервиса", "свой сервер API"],
  ];
  const hdr = head.map((t, i) => ({ text: t, options: { bold: true, color: C.background1,
    fill: { color: i === 5 ? C.accent1 : C.text2 }, align: i ? "center" : "left" } }));
  const body = rows.map(r => r.map((t, i) => ({ text: t, options: {
    bold: i === 0 || i === 5, color: i === 5 ? C.text2 : C.text1,
    fill: { color: i === 5 ? C.background2 : C.background1 }, align: i ? "center" : "left" } })));
  s.addTable([hdr, ...body], { x: 0.6, y: 1.5, w: 12.13, colW: [3.0, 1.75, 1.75, 1.85, 1.85, 1.93],
    rowH: 0.62, fontSize: 14, valign: "middle", border: { type: "solid", pt: 0.75, color: "D5DCEC" },
    margin: [0.05, 0.1, 0.05, 0.1], objectName: "Таблица аналогов" });
  card(s, pres, C, 0.6, 5.5, 12.13, 0.85, C.background2, "Вывод");
  T(s, [
    { text: "Вывод: ", options: { bold: true, color: C.accent1 } },
    { text: "аналоги дают материалы или задачник, но не план под конкретного человека с перестройкой при отставании.", options: { color: C.text1 } },
  ], { x: 0.85, y: 5.5, w: 11.7, h: 0.85, fontSize: 16, valign: "middle" });
  T(s, "Сравнение составлено по публичным описаниям сервисов", { x: 0.6, y: 6.5, w: 8, h: 0.3, fontSize: 11, color: C.accent6, italic: true });
  s.addNotes("Я сравнил приложение с аналогами. roadmap.sh показывает схемы изучения технологий, но схема одна для всех и не превращается в расписание. " +
    "Duolingo хорошо мотивирует ежедневной целью, но план задаёт сам сервис. Курсы на Stepik и Coursera идут в своём темпе. " +
    "Планировщики вроде Notion или Todoist требуют расписывать всё вручную. " +
    "«Маршрут» объединяет граф тем, учёт уровня через тест, расписание под ваше время и автоматическую перестройку, а данные хранит на собственном сервере API без облачных сервисов. " +
    "(Перед защитой сверить таблицу с актуальными версиями сервисов.)");
  return s;
}

function slideArchitecture(pres, C, section) {
  const s = light(pres, "Архитектура: приложение и сервер API", section);
  const col = (title, sub, x, items, name) => {
    card(s, pres, C, x, 1.4, 5.0, 3.45, C.background2, name);
    T(s, [{ text: title, options: { bold: true, color: C.text2, fontSize: 17 } }, { text: "  " + sub, options: { color: C.accent6, fontSize: 13 } }],
      { x: x + 0.25, y: 1.52, w: 4.6, h: 0.4 });
    items.forEach(([t, core], i) => {
      chip(s, pres, C, t, x + 0.25, 2.02 + i * 0.55, 4.5, 0.44, core ? C.text2 : C.background1, core ? C.background1 : C.text2, 13);
      if (i < items.length - 1) T(s, "↓", { x: x + 2.3, y: 2.44 + i * 0.55, w: 0.4, h: 0.14, fontSize: 9, color: C.accent1, align: "center", valign: "middle" });
    });
  };
  col("Приложение", "Flutter, телефон", 0.6, [["Экраны Material 3"], ["Провайдеры Riverpod"], ["PlanService и алгоритм · domain", true],
    ["Репозитории API"], ["ApiClient: токен, ожидание 10 с, ошибки"]], "Приложение");
  col("Сервер API", "Dart, shelf, ноутбук", 7.73, [["Маршруты shelf_router · 39 адресов"], ["Проверка токена, данных и владельца", true],
    ["Репозитории drift"], ["База SQLite · 9 таблиц"]], "Сервер");
  s.addShape(pres.shapes.LINE, { x: 5.75, y: 2.75, w: 1.83, h: 0, line: { color: C.accent1, width: 2.5, endArrowType: "triangle" }, objectName: "Запрос" });
  s.addShape(pres.shapes.LINE, { x: 5.75, y: 3.75, w: 1.83, h: 0, line: { color: C.text2, width: 2.5, beginArrowType: "triangle" }, objectName: "Ответ" });
  T(s, "запрос HTTP + JSON, токен Bearer", { x: 5.65, y: 2.05, w: 2.03, h: 0.62, fontSize: 12, bold: true, color: C.accent1, align: "center", valign: "bottom" });
  T(s, "ответ JSON, код 200 / 201 / 204 / 4xx", { x: 5.65, y: 3.85, w: 2.03, h: 0.62, fontSize: 12, bold: true, color: C.text2, align: "center" });
  const choices = [
    ["Состояние", "Riverpod", "вместо BLoC и Provider: меньше кода, подмена в тестах"],
    ["Данные", "свой сервер API", "вместо Firebase: без облака и ключей, связи и SQL"],
    ["Навигация", "go_router", "redirect закрывает экраны без входа"],
    ["Вход", "PBKDF2 + токен", "вместо Firebase Auth: пароль только хэшем"],
  ];
  choices.forEach(([k, v, why], i) => {
    const x = 0.6 + i * 3.08;
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 5.05, w: 2.88, h: 1.7, rectRadius: 0.12, fill: { color: C.background1 },
      line: { color: "D5DCEC", width: 1 }, objectName: "Выбор " + k });
    T(s, k, { x: x + 0.2, y: 5.17, w: 2.5, h: 0.3, fontSize: 13, color: C.accent6 });
    T(s, v, { x: x + 0.2, y: 5.47, w: 2.5, h: 0.4, fontSize: 17, bold: true, color: C.accent1 });
    T(s, why, { x: x + 0.2, y: 5.9, w: 2.55, h: 0.8, fontSize: 12, color: C.text1 });
  });
  s.addNotes("Система состоит из двух программ. Приложение на Flutter построено по Clean Architecture: экраны берут данные у провайдеров Riverpod, провайдеры вызывают PlanService и алгоритм в слое domain на чистом Dart, а данные получают через репозитории API. " +
    "Все запросы идут через общий клиент ApiClient: он добавляет токен, ждёт ответ не дольше 10 секунд и превращает ошибки в понятные сообщения. " +
    "Сервер API тоже написан на Dart, на библиотеке shelf. Он выбирает обработчик по адресу, проверяет токен, данные и то, что запись принадлежит этому пользователю, и только после этого работает с базой SQLite через drift. " +
    "Приложение к базе напрямую не обращается: получение, добавление, изменение и удаление идут только через API. " +
    "Riverpod выбран вместо BLoC и Provider: меньше шаблонного кода, легко подменять зависимости в тестах. Свой сервер вместо Firebase — нет облака, ключей и внешних сервисов, а данные связаны и требуют SQL. " +
    "Слоистая архитектура себя оправдала: при переходе на сервер заменились только репозитории, алгоритм и экраны остались прежними.");
  return s;
}

function slideAlgorithm(pres, C, section) {
  const s = light(pres, "Алгоритм: план из графа тем за пять шагов", section);
  const steps = [
    ["Граф тем", "Тема — вершина, ребро A → B: A нужно знать до B"],
    ["Исключить известное", "Верный ответ в тесте: тема и её предшественники изучены"],
    ["Алгоритм Кана", "Топологическая сортировка, при равенстве — по сложности. Цикл обнаруживается"],
    ["Раскладка по дням", "Лимит в день = часы в неделю / учебные дни, части от 30 минут"],
    ["Срок и повторения", "Повторения через 1, 3, 7 дней. Не успеваем — подбираем часы"],
  ];
  const d = 0.8, gap = 2.43;
  s.addShape(pres.shapes.LINE, { x: 0.6 + 1.0, y: 1.9, w: gap * 4, h: 0, line: { color: C.accent5, width: 2 }, objectName: "Связь шагов" });
  steps.forEach(([h, t], i) => {
    const cx = 0.6 + 1.0 + i * gap;
    circle(s, pres, C, i + 1, cx - d / 2, 1.5, d, i === 2 ? C.accent1 : C.text2);
    T(s, h, { x: cx - 1.18, y: 2.45, w: 2.36, h: 0.4, fontSize: 15, bold: true, color: C.text2, align: "center" });
    T(s, t, { x: cx - 1.1, y: 2.9, w: 2.2, h: 1.2, fontSize: 13, color: C.text1, align: "center" });
  });
  const stats = [["75", "тем в 4 направлениях"], ["113", "зависимостей между темами"], ["1 · 3 · 7", "дней до повторений"], ["32", "юнит-теста алгоритма"]];
  stats.forEach(([n, l], i) => {
    const x = 0.6 + i * 3.08;
    card(s, pres, C, x, 4.5, 2.85, 1.85, C.background2, "Факт " + l);
    T(s, n, { x: x + 0.25, y: 4.7, w: 2.4, h: 0.85, fontSize: 40, bold: true, color: C.accent1 });
    T(s, l, { x: x + 0.25, y: 5.6, w: 2.4, h: 0.6, fontSize: 14, color: C.text1 });
  });
  s.addNotes("Главная часть работы — алгоритм в слое domain. Направление — это граф тем: нельзя изучать Riverpod, не зная асинхронности Dart. " +
    "Сначала по тесту исключаются известные темы: верный ответ по теме означает, что известны и все темы, которые нужны до неё. " +
    "Затем алгоритм Кана выполняет топологическую сортировку: каждая тема идёт после своих зависимостей. Если в данных случайно появится цикл, алгоритм его найдёт. " +
    "Дальше темы раскладываются по выбранным дням с дневным лимитом, после каждой темы ставятся повторения через 1, 3 и 7 дней по кривой забывания Эббингауза. " +
    "Если план не укладывается в дедлайн, приложение подбирает, сколько часов в неделю нужно. В каталоге 75 тем и 113 зависимостей, алгоритм покрыт юнит-тестами.");
  return s;
}

// ---------- итоговая защита ----------
async function buildFinal() {
  const { pres, C } = newDeck("Маршрут — итоговая защита курсового проекта");
  pres.addSection({ title: "Введение" });
  const s1 = slideTitle(pres, C, "Курсовой проект · итоговая защита", "Введение");
  s1.addNotes("Здравствуйте. Меня зовут Баринов Николай, группа ПО2410. Представляю курсовой проект «Маршрут» — приложение для автоматического формирования персонального плана обучения. Руководитель — Синтиков Еркебулан Канатович. Приложение написано на Flutter и Dart, работает на Android, iPhone и Windows, а данные хранит на собственном сервере API.");
  slideProblem(pres, C, "Введение");
  slideCompetitors(pres, C, "Введение");

  pres.addSection({ title: "Решение" });
  slideArchitecture(pres, C, "Решение");
  slideAlgorithm(pres, C, "Решение");

  // Пример работы алгоритма
  {
    const s = light(pres, "Пример: три темы, 7 часов в неделю, дедлайн 14.10", "Решение");
    const rows = [["12.10", "Основы Dart", "60"], ["13.10", "Повторение: Основы Dart", "15"], ["13.10", "Виджеты, часть 1 из 2", "45"],
      ["14.10", "Виджеты, часть 2 из 2", "15"], ["14.10", "Состояние, часть 1 из 2", "45"], ["15.10", "Повторение: Основы Dart", "15"],
      ["15.10", "Повторение: Виджеты", "15"], ["15.10", "Состояние, часть 2 из 2", "15"]];
    const hdr = ["Дата", "Занятие", "Мин"].map((t, i) => ({ text: t, options: { bold: true, color: C.background1, fill: { color: C.text2 }, align: i === 1 ? "left" : "center" } }));
    const body = rows.map(r => r.map((t, i) => ({ text: t, options: {
      color: r[1].startsWith("Повторение") ? C.accent6 : C.text1, bold: r[0] === "15.10" && r[1].startsWith("Состояние"),
      fill: { color: r[0] === "15.10" && r[1].startsWith("Состояние") ? "FFE3C4" : C.background1 }, align: i === 1 ? "left" : "center" } })));
    s.addTable([hdr, ...body], { x: 0.6, y: 1.5, w: 6.4, colW: [1.1, 4.3, 1.0], rowH: 0.5, fontSize: 14, valign: "middle",
      border: { type: "solid", pt: 0.75, color: "D5DCEC" }, margin: [0.03, 0.1, 0.03, 0.1], objectName: "Таблица расписания" });
    T(s, "Дневной лимит: 7 · 60 / 7 = 60 минут. Повторения занимают часть лимита.", { x: 0.6, y: 6.1, w: 6.4, h: 0.6, fontSize: 13, color: C.accent6 });
    card(s, pres, C, 7.4, 1.5, 3.0, 4.95, C.text2, "Итог примера");
    T(s, "ИТОГ", { x: 7.65, y: 1.7, w: 2.5, h: 0.3, fontSize: 13, bold: true, color: C.accent4, charSpacing: 2 });
    T(s, [
      { text: "Изучение заканчивается 15.10, на день позже дедлайна.", options: { breakLine: true } },
      { text: " ", options: { breakLine: true, fontSize: 8 } },
      { text: "Приложение предупреждает и предлагает 8 ч в неделю: лимит 75 минут, последняя тема 14.10.", options: { bold: true, color: C.accent4 } },
    ], { x: 7.65, y: 2.1, w: 2.55, h: 4.1, fontSize: 16, color: C.background1 });
    phone(s, "19_preview", 10.7, 1.5, 4.95, "Предпросмотр плана", C);
    s.addNotes("Покажу работу алгоритма на маленьком примере: три темы по часу, каждая зависит от предыдущей, 7 часов в неделю, все дни, дедлайн 14 октября. " +
      "Дневной лимит — 60 минут. Из-за повторений тема «Виджеты» делится на две части, и последняя тема заканчивается 15 октября, на день позже срока. " +
      "Алгоритм это замечает и предлагает 8 часов в неделю: тогда лимит 75 минут и план укладывается в срок. В приложении это кнопка «Установить N ч/нед» на экране предпросмотра.");
  }

  pres.addSection({ title: "1 семестр" });
  {
    const s = light(pres, "Сценарий 1 семестра работает без ошибок", "1 семестр");
    const flow = ["Splash", "Регистрация", "Вход", "Главная", "Навигация", "Профиль", "Основной раздел", "Выход"];
    const ws = [1.05, 1.45, 0.85, 1.1, 1.25, 1.1, 1.85, 0.95];
    let x = 0.6;
    flow.forEach((t, i) => {
      chip(s, pres, C, t, x, 1.4, ws[i], 0.42, i === 7 ? C.accent1 : C.background2, i === 7 ? C.background1 : C.text2, 12);
      x += ws[i];
      if (i < 7) { T(s, "→", { x, y: 1.4, w: 0.33, h: 0.42, fontSize: 14, bold: true, color: C.accent1, align: "center", valign: "middle" }); x += 0.33; }
    });
    const shots = [["01_splash", "Заставка, автовход"], ["03_register_validation", "Ошибки под полями"], ["04_login_error", "Неверный пароль"],
      ["05_home", "Прогресс и задачи"], ["10_profile", "Профиль и «Выйти»"]];
    const h = 4.25, w = h * PHONE_RATIO, g = (12.13 - 5 * w) / 4;
    shots.forEach(([n, c], i) => phone(s, n, 0.6 + i * (w + g), 2.1, h, c, C));
    s.addNotes("Покажу обязательный сценарий первого семестра. Заставка с логотипом сама переходит на вход или, если сессия сохранена, сразу на главную. " +
      "Регистрация проверяет каждое поле: пустые поля, формат email, пароль из букв и цифр, совпадение паролей, уникальность email. " +
      "При неверном пароле вход показывает понятное сообщение, есть ссылка на регистрацию. Пользователь хранится в базе на сервере, после входа сервер выдаёт токен, и открывается главная с прогрессом и задачами на сегодня. " +
      "Пять вкладок внизу: Главная, План, Темы, Статистика, Профиль. В профиле кнопка «Выйти»: после выхода открывается вход, а закрытые экраны без входа недоступны — это делает redirect в go_router. " +
      "Тот же сценарий автоматически проходит интеграционный тест.");
  }
  {
    const s = light(pres, "Основной раздел: план за четыре шага", "1 семестр");
    const shots = [["16_direction", "Направление"], ["17_diagnostic", "Диагностический тест"], ["18_schedule", "Часы, дни, дедлайн"], ["19_preview", "Готовый план"]];
    const h = 4.3, w = h * PHONE_RATIO, g = 0.3;
    shots.forEach(([n, c], i) => {
      const x = 0.6 + i * (w + g);
      phone(s, n, x, 1.45, h, null, C);
      circle(s, pres, C, i + 1, x, 5.95, 0.45);
      T(s, c, { x: x + 0.55, y: 5.85, w: w - 0.45, h: 0.65, fontSize: 13, bold: true, color: C.text2, valign: "middle" });
    });
    const rx = 0.6 + 4 * (w + g) + 0.05;
    card(s, pres, C, rx, 1.45, 12.73 - rx, 5.05, C.background2, "Пояснение");
    T(s, [
      { text: "4 направления", options: { bold: true, color: C.accent1, breakLine: true } },
      { text: "Flutter, Python, английский A1–B1, алгоритмы", options: { breakLine: true } },
      { text: " ", options: { breakLine: true, fontSize: 8 } },
      { text: "32 вопроса теста", options: { bold: true, color: C.accent1, breakLine: true } },
      { text: "исключают уже знакомые темы", options: { breakLine: true } },
      { text: " ", options: { breakLine: true, fontSize: 8 } },
      { text: "Предпросмотр", options: { bold: true, color: C.accent1, breakLine: true } },
      { text: "порядок тем, часы и дата окончания до старта", options: {} },
    ], { x: rx + 0.25, y: 1.7, w: 12.73 - rx - 0.5, h: 4.6, fontSize: 15, color: C.text1 });
    s.addNotes("Основной раздел — создание плана. Пользователь выбирает одно из четырёх направлений, отвечает на вопросы диагностического теста, указывает часы в неделю, учебные дни и дедлайн. " +
      "На предпросмотре видно, в каком порядке пойдут темы, сколько часов займёт изучение и повторения и когда план закончится. Кнопка «Начать обучение» сохраняет план, и задачи появляются на главной.");
  }

  pres.addSection({ title: "2 семестр" });
  {
    const s = light(pres, "Анализ версии 1 семестра: 8 недостатков исправлены", "2 семестр");
    const rows = [
      ["Пароль — однократный SHA-256", "Высокий", "PBKDF2-HMAC-SHA256, 100 000 итераций"],
      ["Нет удаления аккаунта", "Средний", "Удаление с паролем и каскадом данных"],
      ["Не настроены уведомления Android", "Высокий", "Приёмники, RECEIVE_BOOT_COMPLETED"],
      ["Цветной значок уведомления", "Низкий", "Белый векторный значок"],
      ["Иконка Flutter и имя «marshrut»", "Средний", "Своя иконка и название «Маршрут»"],
      ["Нет релизного APK", "Высокий", "APK и Windows собираются автоматически"],
      ["Тесты только вручную", "Средний", "GitHub Actions на каждое изменение"],
      ["Сценарии 2 семестра без тестов", "Средний", "Виджет-тесты CRUD, найдена ошибка № 12"],
    ];
    const pc = { "Высокий": C.accent1, "Средний": C.text2, "Низкий": C.accent6 };
    const hdr = ["Недостаток", "Приоритет", "Что сделано"].map(t => ({ text: t, options: { bold: true, color: C.background1, fill: { color: C.text2 } } }));
    const body = rows.map(r => [
      { text: r[0], options: { color: C.text1 } },
      { text: r[1], options: { color: pc[r[1]], bold: true, align: "center" } },
      { text: r[2], options: { color: C.text1 } },
    ]);
    s.addTable([hdr, ...body], { x: 0.6, y: 1.45, w: 12.13, colW: [4.6, 1.6, 5.93], rowH: 0.52, fontSize: 14, valign: "middle",
      border: { type: "solid", pt: 0.75, color: "D5DCEC" }, margin: [0.03, 0.12, 0.03, 0.12], objectName: "Таблица недостатков" });
    T(s, "Как искали: сверка с критериями, документацией пакетов и рекомендациями OWASP, ручная проверка, новые тесты сценариев",
      { x: 0.6, y: 6.25, w: 12.13, h: 0.55, fontSize: 13, color: C.accent6, italic: true });
    s.addNotes("Во втором семестре я заново проверил первую версию: сверил её с критериями, с документацией пакетов, с рекомендациями OWASP по паролям, вручную посмотрел оформление и написал тесты сценариев. " +
      "Нашлось восемь недостатков. Самые важные — слабое хэширование паролей, отсутствие релизной сборки и неполная настройка уведомлений Android. " +
      "Все восемь исправлены: пароли теперь хэшируются PBKDF2, появилось удаление аккаунта, своя иконка, APK собирается автоматически, а тесты запускаются на каждом изменении.");
  }
  {
    const s = light(pres, "Полный функционал и дополнительные возможности", "2 семестр");
    T(s, "Основные сценарии связаны между собой: отметка занятия меняет прогресс, статистику и план", { x: 0.6, y: 1.45, w: 4.3, h: 0.95, fontSize: 15, color: C.text1 });
    const feats = ["Перепланирование", "Pomodoro", "Несколько планов", "Свои темы", "Заметки", "Поиск", "Фильтры", "Избранное",
      "Категории", "Уведомления", "История", "Графики", "Тёмная тема", "iPhone и Windows"];
    feats.forEach((t, i) => {
      const col = i % 2, row = Math.floor(i / 2);
      const main = i < 5;
      chip(s, pres, C, t, 0.6 + col * 2.2, 2.6 + row * 0.56, 2.05, 0.44, main ? C.text2 : C.background2, main ? C.background1 : C.text2, 13);
    });
    const shots = [["06_plan", "План по дням"], ["09_stats", "Статистика"], ["12_pomodoro", "Pomodoro"]];
    const h = 4.85, w = h * PHONE_RATIO, g = 0.35;
    const x0 = 12.73 - (3 * w + 2 * g);
    shots.forEach(([n, c], i) => phone(s, n, x0 + i * (w + g), 1.45, h, c, C));
    s.addNotes("Во втором семестре основной функционал доведён до полного объёма. Если пользователь пропустил занятия, на главной появляется баннер, и кнопка «Перестроить» переносит остаток плана вперёд, сохраняя выполненное. " +
      "Можно вести несколько планов, добавлять свои темы и заметки. Из дополнительных функций — поиск, фильтры по категориям, избранное, ежедневное напоминание, таймер Pomodoro с уведомлением, история и графики прогресса на fl_chart, светлая и тёмная тема.");
  }
  {
    const s = light(pres, "Данные: 9 таблиц SQLite на сервере, доступ только через API", "2 семестр");
    const box = (name, sub, x, y, w, fill, tc) => {
      s.addText([{ text: name, options: { bold: true, fontSize: 14, breakLine: true } }, { text: sub, options: { fontSize: 11 } }],
        { shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.1, x, y, w, h: 0.6, fill: { color: fill || C.background2 },
          line: { type: "none" }, color: tc || C.text2, align: "center", valign: "middle", margin: 0.03, objectName: "Таблица " + name });
    };
    const line = (x1, y1, x2, y2) => s.addShape(pres.shapes.LINE, { x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1),
      flipV: (y2 < y1) !== (x2 < x1), line: { color: C.accent6, width: 1.25, endArrowType: "triangle" }, objectName: "Связь" });
    const kids = [["plans", "планы"], ["custom_topics", "свои темы"], ["notes", "заметки"], ["favorites", "избранное"], ["pomodoro_logs", "помидоры"], ["api_tokens", "токены входа"]];
    const kx = 3.2, kw = 2.2, ky = 1.5, step = 0.8;
    const ux = 0.6, uw = 1.9, uy = ky + 2.5 * step;
    box("users", "пользователи", ux, uy, uw, C.text2, C.background1);
    kids.forEach(([n, d], i) => {
      const y = ky + i * step;
      box(n, d, kx, y, kw, i === 0 ? C.accent1 : (i === 5 ? "FFE3C4" : C.background2), i === 0 ? C.background1 : C.text2);
      line(ux + uw, uy + 0.3, kx, y + 0.3);
    });
    const px = 6.1, pw = 2.0;
    [["plan_topics", "темы плана"], ["sessions", "занятия"]].forEach(([n, d], i) => {
      const y = 1.45 + i * 0.85;
      box(n, d, px, y, pw, C.background2, C.text2);
      line(kx + kw, ky + 0.3, px, y + 0.3);
    });
    card(s, pres, C, 6.1, 3.35, 2.0, 2.75, C.text2, "Каскад");
    T(s, [{ text: "1 : N", options: { bold: true, color: C.accent4, fontSize: 20, breakLine: true } },
      { text: "ON DELETE CASCADE: удаление аккаунта удаляет все его данные и токены", options: { color: C.background1 } }],
      { x: 6.28, y: 3.5, w: 1.7, h: 2.5, fontSize: 12 });
    T(s, "Каталог тем — JSON на сервере, приложение получает его через GET /api/directions", { x: 0.6, y: 6.4, w: 7.6, h: 0.35, fontSize: 12, color: C.accent6, italic: true });
    card(s, pres, C, 8.5, 1.45, 4.23, 5.3, C.background2, "CRUD");
    T(s, "ПОЛНЫЙ CRUD ЧЕРЕЗ API", { x: 8.75, y: 1.62, w: 3.8, h: 0.3, fontSize: 13, bold: true, color: C.accent1, charSpacing: 1 });
    const crud = [["Заметки", "/api/notes"], ["Свои темы", "/api/custom-topics"], ["Планы", "/api/plans"]];
    crud.forEach(([h, url], i) => {
      const y = 2.05 + i * 0.95;
      T(s, h, { x: 8.75, y, w: 3.8, h: 0.32, fontSize: 15, bold: true, color: C.text2 });
      T(s, [{ text: "GET · POST · PUT · DELETE  ", options: { color: C.text1 } }, { text: url, options: { color: C.accent6, fontFace: "Courier New", fontSize: 11 } }],
        { x: 8.75, y: y + 0.34, w: 3.85, h: 0.45, fontSize: 12 });
    });
    T(s, "КОДЫ ОТВЕТОВ", { x: 8.75, y: 4.95, w: 3.8, h: 0.3, fontSize: 13, bold: true, color: C.accent1, charSpacing: 1 });
    ["200", "201", "204", "400", "401", "404", "500"].forEach((c, i) => {
      chip(s, pres, C, c, 8.75 + (i % 4) * 0.93, 5.32 + Math.floor(i / 4) * 0.55, 0.8, 0.42, c[0] === "2" ? C.text2 : C.background1, c[0] === "2" ? C.background1 : C.accent1, 13);
    });
    s.addNotes("Данные хранятся в базе SQLite на сервере, работа с базой идёт через drift. Таблиц девять: у пользователя есть планы, свои темы, заметки, избранное, история «помидоров» и токены входа; план состоит из тем и занятий. " +
      "Все внешние ключи объявлены с каскадным удалением: удаление аккаунта удаляет все данные пользователя и его токены. " +
      "Приложение к базе напрямую не обращается: у сервера 39 адресов API, и полный CRUD — получение, добавление, изменение и удаление — есть у заметок, своих тем и планов. " +
      "Сервер отвечает кодами HTTP: 200, 201 и 204 при успехе, 400 при неверных данных, 401 без токена, 404 если запись не найдена или чужая, 500 при сбое. Приложение показывает каждую ошибку понятным сообщением.");
  }
  {
    const s = light(pres, "Демонстрация: каждое действие видно в журнале сервера", "2 семестр");
    const h = 4.9, w = h * PHONE_RATIO;
    phone(s, "26_server_address", 0.6, 1.45, h, "Адрес сервера", C);
    phone(s, "13_notes", 0.6 + w + 0.35, 1.45, h, "Заметки", C);
    const tx = 0.6 + 2 * w + 0.8, tw = 12.73 - tx;
    card(s, pres, C, tx, 1.45, tw, 2.75, C.text1, "Журнал сервера");
    T(s, "ОКНО СЕРВЕРА НА НОУТБУКЕ", { x: tx + 0.25, y: 1.6, w: tw - 0.5, h: 0.3, fontSize: 12, bold: true, color: C.accent4, charSpacing: 1 });
    const log = [["POST  ", "/api/auth/login", "200"], ["POST  ", "/api/notes", "201"], ["PUT   ", "/api/notes/1", "204"], ["DELETE", "/api/notes/1", "204"], ["GET   ", "/api/notes", "401"]];
    T(s, log.map(([m, u, c], i) => ({ text: m + " " + u.padEnd(17, " ") + "→ " + c, options: { color: c[0] === "2" ? C.background1 : C.accent4, breakLine: i < log.length - 1 } })),
      { x: tx + 0.25, y: 2.0, w: tw - 0.5, h: 2.05, fontSize: 14, fontFace: "Courier New", paraSpaceAfter: 2 });
    const steps = ["Запустить сервер, телефон в той же сети Wi-Fi", "Создать, изменить и удалить заметку", "В журнале: POST → 201, PUT и DELETE → 204", "Выключить сервер: «Нет связи с сервером»"];
    steps.forEach((t, i) => {
      const y = 4.45 + i * 0.58;
      circle(s, pres, C, i + 1, tx, y, 0.42);
      T(s, t, { x: tx + 0.6, y, w: tw - 0.6, h: 0.42, fontSize: 14, color: C.text1, valign: "middle" });
    });
    s.addNotes("Покажу, что данные идут только через API. Сервер запущен на ноутбуке, его окно видно, телефон подключён к той же сети Wi-Fi; адрес сервера вводится на экране входа и проверяется запросом к серверу. " +
      "Создаю заметку — в журнале сервера появляется строка POST /api/notes с кодом 201. Изменяю её — PUT с кодом 204, удаляю — DELETE с кодом 204. " +
      "Теперь выключаю сервер и пробую сохранить заметку: приложение показывает красное сообщение «Нет связи с сервером», а данные не меняются. Включаю сервер, повторяю действие — оно сохраняется.");
  }
  {
    const s = light(pres, "Профиль и безопасность", "2 семестр");
    const h = 4.95, w = h * PHONE_RATIO;
    phone(s, "10_profile", 0.6, 1.45, h, "Профиль", C);
    phone(s, "25_delete_account", 0.6 + w + 0.4, 1.45, h, "Удаление аккаунта", C);
    const rx = 0.6 + 2 * w + 1.0;
    T(s, "Профиль", { x: rx, y: 1.5, w: 5.5, h: 0.45, fontSize: 20, bold: true, color: C.text2 });
    T(s, [
      { text: "Редактирование имени, email и цвета аватара", options: { bullet: true, breakLine: true } },
      { text: "Смена пароля с проверкой текущего", options: { bullet: true, breakLine: true } },
      { text: "Тема оформления и ежедневное напоминание", options: { bullet: true, breakLine: true } },
      { text: "Удаление аккаунта с подтверждением паролем", options: { bullet: true } },
    ], { x: rx, y: 2.0, w: 12.73 - rx, h: 1.9, fontSize: 15, color: C.text1, paraSpaceAfter: 6 });
    card(s, pres, C, rx, 4.1, 12.73 - rx, 2.3, C.text2, "Безопасность");
    T(s, "100 000", { x: rx + 0.3, y: 4.3, w: 3, h: 0.8, fontSize: 40, bold: true, color: C.accent4 });
    T(s, "итераций PBKDF2-HMAC-SHA256", { x: rx + 0.3, y: 5.1, w: 3.2, h: 0.4, fontSize: 14, bold: true, color: C.background1 });
    T(s, "Соль 16 байт. Токен входа — 32 случайных байта, в базе только его SHA-256, действует 30 дней, удаляется при выходе.",
      { x: rx + 3.4, y: 4.35, w: 12.73 - rx - 3.65, h: 1.9, fontSize: 13, color: C.background1, valign: "middle" });
    s.addNotes("Профиль показывает данные пользователя и статистику, позволяет изменить имя, email и цвет аватара, сменить пароль и удалить аккаунт — для этого нужно ввести пароль ещё раз. " +
      "Пароли не хранятся в открытом виде: используется PBKDF2-HMAC-SHA256 со 100 000 итераций и случайной солью. В формате хэша записано число итераций, поэтому его можно увеличить в следующей версии. " +
      "После входа сервер выдаёт токен из 32 случайных байт; в базе хранится только его хэш SHA-256, поэтому копия базы не даёт ни паролей, ни действующих токенов. Токен действует 30 дней и удаляется при выходе.");
  }
  {
    const s = light(pres, "UI/UX: одна система на телефоне и компьютере", "2 семестр");
    const dw = 6.6, dh = dw * 1024 / 1624;
    s.addImage({ path: path.join(IMG, "22_desktop_home.png"), x: 0.6, y: 1.45, w: dw, h: dh, objectName: "Скриншот Windows", altText: "Главная в окне Windows" });
    T(s, [
      { text: "Material 3, тёмно-синий и оранжевый", options: { bullet: true, breakLine: true } },
      { text: "Боковая панель вместо нижней от 840 px", options: { bullet: true, breakLine: true } },
      { text: "Пустые состояния и подтверждение необратимых действий", options: { bullet: true } },
    ], { x: 0.6, y: 1.45 + dh + 0.2, w: dw + 0.6, h: 1.0, fontSize: 13, color: C.text1, paraSpaceAfter: 2 });
    const h = 4.45, w = h * PHONE_RATIO;
    phone(s, "20_home_dark", 12.73 - 2 * w - 0.35, 1.45, h, "Тёмная тема", C);
    phone(s, "21_stats_dark", 12.73 - w, 1.45, h, "Графики", C);
    s.addNotes("Интерфейс построен на Material 3 в фирменных цветах: тёмно-синий — спокойный фон для учёбы, оранжевым выделены кнопки действий и прогресс. " +
      "Есть светлая и тёмная тема. Вёрстка адаптивная: на широком экране, например в окне Windows, нижняя навигация заменяется боковой панелью, а содержимое не растягивается шире 720 пикселей. " +
      "Для пустых списков есть подсказки, а удаление всегда требует подтверждения. Все экраны проверены матрицей из 280 снимков в семи вариантах.");
  }
  {
    const s = light(pres, "Тестирование: 137 автотестов и 27 исправленных ошибок", "2 семестр");
    const stats = [["137", "модульных и виджет-тестов"], ["45", "тест-кейсов"], ["280", "снимков экранов проверено"], ["27", "ошибок найдено и исправлено"]];
    stats.forEach(([n, l], i) => {
      const x = 0.6 + i * 3.08;
      card(s, pres, C, x, 1.45, 2.85, 1.6, C.background2, "Факт " + l);
      T(s, n, { x: x + 0.25, y: 1.55, w: 2.4, h: 0.85, fontSize: 44, bold: true, color: C.accent1 });
      T(s, l, { x: x + 0.25, y: 2.4, w: 2.45, h: 0.55, fontSize: 13, color: C.text1 });
    });
    s.addChart(pres.charts.BAR, [{ name: "Тестов", labels: ["Алгоритм", "Утилиты и роутер", "Сервер API", "Виджет-тесты", "Репозитории БД", "Клиент API", "Интеграционный"], values: [32, 29, 23, 21, 18, 14, 1] }], {
      x: 0.6, y: 3.25, w: 6.6, h: 3.5, barDir: "bar", chartColors: [HEX.dk2], showValue: true, dataLabelPosition: "outEnd",
      dataLabelColor: HEX.dk1, dataLabelFontSize: 12, dataLabelFontFace: "+mn-lt", catAxisLabelColor: HEX.dk1, catAxisLabelFontSize: 12,
      catAxisLabelFontFace: "+mn-lt", valAxisHidden: true, valGridLine: { style: "none" }, catGridLine: { style: "none" },
      catAxisOrientation: "maxMin", showLegend: false, showTitle: true, title: "Состав автотестов", titleFontSize: 14,
      titleColor: HEX.dk2, titleFontFace: "+mn-lt", barGapWidthPct: 50, objectName: "Диаграмма тестов" });
    card(s, pres, C, 7.6, 3.3, 5.13, 3.4, C.text2, "CI");
    T(s, "GITHUB ACTIONS НА КАЖДОЕ ИЗМЕНЕНИЕ", { x: 7.85, y: 3.5, w: 4.7, h: 0.3, fontSize: 13, bold: true, color: C.accent4, charSpacing: 1 });
    ["Формат, flutter analyze, все тесты", "Интеграционный тест с HTTP-сервером", "Сборки: APK, IPA для iPhone, Windows", "Программа-сервер API для Windows"].forEach((t, i) => {
      circle(s, pres, C, i + 1, 7.85, 4.0 + i * 0.62, 0.42);
      T(s, t, { x: 8.45, y: 4.0 + i * 0.62, w: 4.1, h: 0.42, fontSize: 14, color: C.background1, valign: "middle" });
    });
    s.addNotes("Приложение проверяют 137 модульных и виджет-тестов. 32 проверяют алгоритм, 23 — сервер API: коды ответов, отказ без токена, защиту чужих записей, CRUD; 14 — клиент API: выключенный сервер, таймаут, ответ 401. " +
      "Виджет-тесты запускают приложение вместе с настоящим сервером API, у которого база в памяти, поэтому проверяется весь путь данных — от экрана до базы. Интеграционный тест проходит сценарий в настоящем приложении с настоящим HTTP-сервером. " +
      "В документе 45 тест-кейсов и журнал из 27 найденных и исправленных ошибок. GitHub Actions на каждое изменение запускает все проверки и собирает APK, файл для iPhone, версию для Windows и программу-сервер.");
  }
  {
    const s = light(pres, "Курсовая работа и релизная сборка", "2 семестр");
    const parts = [["Введение", "актуальность, цель, 9 задач"], ["Глава 1", "предметная область, аналоги, выбор технологий"],
      ["Глава 2", "архитектура, база и API сервера, алгоритм, экраны, тесты"], ["Заключение", "результаты по каждой задаче"],
      ["Литература", "50 источников по ГОСТ"], ["Приложения А–Л", "код алгоритма, сервера и клиента API"]];
    parts.forEach(([h, d], i) => {
      const col = i % 2, row = Math.floor(i / 2);
      const x = 0.6 + col * 3.75, y = 1.45 + row * 1.25;
      card(s, pres, C, x, y, 3.55, 1.08, C.background2, "Раздел " + h);
      T(s, h, { x: x + 0.22, y: y + 0.13, w: 3.1, h: 0.38, fontSize: 16, bold: true, color: C.text2 });
      T(s, d, { x: x + 0.22, y: y + 0.52, w: 3.15, h: 0.5, fontSize: 12, color: C.text1 });
    });
    T(s, [{ text: "105 страниц", options: { bold: true, color: C.accent1 } }, { text: " · Times New Roman 14, интервал 1,5 · DOCX и PDF", options: { color: C.accent6 } }],
      { x: 0.6, y: 5.3, w: 7.3, h: 0.4, fontSize: 14 });
    card(s, pres, C, 8.3, 1.45, 4.43, 4.95, C.text2, "Релиз");
    s.addImage({ path: path.join(IMG, "icon.png"), x: 8.6, y: 1.75, w: 0.9, h: 0.9, objectName: "Иконка", altText: "Иконка «Маршрут»" });
    T(s, "Релиз", { x: 9.7, y: 1.9, w: 2.8, h: 0.6, fontSize: 24, bold: true, color: C.background1, valign: "middle" });
    T(s, [
      { text: "flutter build apk --release", options: { fontFace: "Courier New", color: C.accent4, breakLine: true } },
      { text: " ", options: { breakLine: true, fontSize: 8 } },
      { text: "GitHub Actions собирает APK для Android, IPA для iPhone, Windows и сервер API", options: { bullet: true, breakLine: true } },
      { text: "iPhone: установка через Sideloadly", options: { bullet: true, breakLine: true } },
      { text: "Без облака и ключей: сервер на своём ноутбуке", options: { bullet: true } },
    ], { x: 8.6, y: 2.95, w: 3.9, h: 3.2, fontSize: 14, color: C.background1, paraSpaceAfter: 6 });
    s.addNotes("Пояснительная записка — 105 страниц: введение с целью и девятью задачами, теоретическая глава с анализом аналогов и обоснованием технологий, практическая глава с архитектурой, базой данных и API сервера, схемой алгоритма и скриншотами, заключение, 50 источников и приложения с кодом алгоритма, сервера и клиента API. " +
      "Сборки делает GitHub Actions: APK для Android командой flutter build apk --release, файл IPA для iPhone, который ставится через Sideloadly, версию для Windows и программу-сервер для ноутбука.");
  }

  pres.addSection({ title: "Итоги" });
  {
    const s = pres.addSlide({ masterName: "DARK", sectionTitle: "Итоги" });
    T(s, "Итоги", { x: 0.7, y: 0.6, w: 8, h: 0.9, fontSize: 40, bold: true, color: C.background1 });
    const res = [
      "Приложение строит персональный план по графу тем, тесту, времени и дедлайну",
      "Клиент-сервер: приложение Flutter и свой сервер API на Dart с SQLite",
      "Полный сценарий, CRUD, перепланирование, Pomodoro, статистика, уведомления",
      "137 тестов, CI и сборки для Android, iPhone и Windows",
    ];
    res.forEach((t, i) => {
      circle(s, pres, C, i + 1, 0.7, 1.85 + i * 0.95, 0.6);
      T(s, t, { x: 1.55, y: 1.85 + i * 0.95, w: 6.8, h: 0.6, fontSize: 17, color: C.background1, valign: "middle" });
    });
    T(s, "Спасибо за внимание! Готов ответить на вопросы", { x: 0.7, y: 5.9, w: 8, h: 0.6, fontSize: 22, bold: true, color: C.accent1 });
    phone(s, "09_stats", 8.0, 0.75, 6.0, null, C);
    phone(s, "12_pomodoro", 10.25, 1.4, 5.25, null, C);
    s.addNotes("Подведу итог. Все задачи курсовой выполнены: приложение «Маршрут» строит персональный план обучения с учётом знаний, времени и дедлайна и перестраивает его при отставании. " +
      "Приложение работает с данными только через собственный сервер API, покрыто тестами и собирается автоматически для Android, iPhone и Windows. Дальнейшее развитие — размещение сервера в интернете с шифрованием HTTPS и экспорт плана. Спасибо за внимание, готов ответить на вопросы.");
  }
  const file = path.join(OUT, "Маршрут_итоговая_защита.pptx");
  await pres.writeFile({ fileName: file });
  await applyTheme(file, THEME);
  return file;
}

// ---------- защита концепции ----------
async function buildConcept() {
  const { pres, C } = newDeck("Маршрут — защита концепции");
  pres.addSection({ title: "Тема" });
  const s1 = slideTitle(pres, C, "Защита концепции курсового проекта", "Тема");
  s1.addNotes("Здравствуйте. Меня зовут Баринов Николай, группа ПО2410. Моя тема — создание приложения для автоматического формирования персонального плана обучения. Приложение называется «Маршрут», оно разрабатывается на Flutter и Dart. Руководитель — Синтиков Еркебулан Канатович.");
  slideProblem(pres, C, "Тема");
  slideCompetitors(pres, C, "Тема");
  pres.addSection({ title: "Стек и архитектура" });
  slideArchitecture(pres, C, "Стек и архитектура");
  slideAlgorithm(pres, C, "Стек и архитектура");
  pres.addSection({ title: "UI/UX и roadmap" });
  {
    const s = light(pres, "UI/UX: от сценария пользователя к экранам", "UI/UX и roadmap");
    const flow = ["Splash", "Вход", "Направление", "Тест", "Расписание", "Главная"];
    const ws = [1.1, 0.9, 1.5, 0.9, 1.45, 1.15];
    let x = 0.6;
    flow.forEach((t, i) => {
      chip(s, pres, C, t, x, 1.4, ws[i], 0.42, i === 5 ? C.accent1 : C.background2, i === 5 ? C.background1 : C.text2, 13);
      x += ws[i];
      if (i < 5) { T(s, "→", { x, y: 1.4, w: 0.4, h: 0.42, fontSize: 14, bold: true, color: C.accent1, align: "center", valign: "middle" }); x += 0.4; }
    });
    T(s, "⇄ План, Темы, Статистика, Профиль", { x: x + 0.1, y: 1.4, w: 12.73 - x - 0.1, h: 0.42, fontSize: 13, bold: true, color: C.text2, valign: "middle" });
    const h = 4.45, w = h * PHONE_RATIO, g = 0.3;
    [["05_home", "Главная"], ["06_plan", "План"], ["20_home_dark", "Тёмная тема"]].forEach(([n, c], i) => phone(s, n, 0.6 + i * (w + g), 2.15, h, c, C));
    const rx = 0.6 + 3 * (w + g) + 0.2;
    T(s, [
      { text: "Material 3, светлая и тёмная тема", options: { bullet: true, breakLine: true } },
      { text: "Тёмно-синий #1A3A8F — спокойный фон, оранжевый #F57C00 — действия и прогресс", options: { bullet: true, breakLine: true } },
      { text: "5 вкладок внизу: всё главное в один тап", options: { bullet: true, breakLine: true } },
      { text: "На главной только то, что нужно сегодня", options: { bullet: true, breakLine: true } },
      { text: "Ошибки под каждым полем, пустые состояния с подсказкой", options: { bullet: true, breakLine: true } },
      { text: "Адаптивность: боковая панель на широком экране, поворот экрана", options: { bullet: true } },
    ], { x: rx, y: 2.15, w: 12.73 - rx, h: 4.0, fontSize: 14, color: C.text1, paraSpaceAfter: 6 });
    T(s, "Кликабельный прототип: docs/concept/wireframes.html, user flow: docs/concept/user_flow.md",
      { x: rx, y: 6.25, w: 12.73 - rx, h: 0.5, fontSize: 12, color: C.accent6, italic: true });
    s.addNotes("Интерфейс я проектировал от сценария пользователя. После заставки человек входит или регистрируется, проходит онбординг из трёх шагов — направление, тест, расписание — и попадает на главную, где видит прогресс и задачи на сегодня. " +
      "Пять вкладок внизу ведут к плану, темам, статистике и профилю. Material 3 со светлой и тёмной темой в фирменных цветах: тёмно-синий создаёт спокойный фон, оранжевым выделены действия и прогресс. " +
      "На широком экране вкладки переезжают в боковую панель. Кликабельный прототип открывается в браузере и показывает все ключевые экраны и переходы.");
  }
  {
    const s = light(pres, "Roadmap: от концепции к релизу", "UI/UX и roadmap");
    const st = [["Этап 0", "Концепция", "Тема, аналоги, архитектура, прототип"], ["Семестр 1", "Авторизация", "Splash, регистрация, вход, навигация, профиль, выход"],
      ["Семестр 1", "Основной раздел", "Генератор плана, онбординг и тест, главная, введение и глава 1"],
      ["Семестр 2", "Полный функционал", "Сервер API, CRUD через API, перепланирование, Pomodoro, графики"],
      ["Семестр 2", "Релиз", "Тесты, APK и iPhone, практическая глава, итоговая защита"]];
    const gap = 2.43;
    s.addShape(pres.shapes.LINE, { x: 1.6, y: 2.0, w: gap * 4, h: 0, line: { color: C.accent5, width: 2 }, objectName: "Линия времени" });
    st.forEach(([p, h, d], i) => {
      const cx = 1.6 + i * gap;
      circle(s, pres, C, i, cx - 0.4, 1.6, 0.8, i === 0 ? C.accent1 : C.text2);
      T(s, p.toUpperCase(), { x: cx - 1.1, y: 2.6, w: 2.2, h: 0.3, fontSize: 12, bold: true, color: C.accent1, align: "center", charSpacing: 1 });
      T(s, h, { x: cx - 1.1, y: 2.95, w: 2.2, h: 0.4, fontSize: 17, bold: true, color: C.text2, align: "center" });
      T(s, d, { x: cx - 1.1, y: 3.4, w: 2.2, h: 1.3, fontSize: 13, color: C.text1, align: "center" });
    });
    card(s, pres, C, 0.6, 5.05, 12.13, 1.3, C.text2, "Итог");
    T(s, [
      { text: "«Маршрут» превращает хаотичное самообучение в план по дням. ", options: { bold: true, color: C.background1 } },
      { text: "Данные на своём сервере API, без облака и ключей. Спасибо за внимание!", options: { color: C.accent4 } },
    ], { x: 0.9, y: 5.05, w: 11.6, h: 1.3, fontSize: 18, valign: "middle" });
    s.addNotes("Работа разбита на этапы. Сегодня защищается концепция: тема, архитектура и прототип. В первом семестре реализуется обязательный сценарий — заставка, регистрация, вход, главная, навигация, профиль, выход — и генератор плана. " +
      "Во втором семестре — сервер API, через который приложение получает и изменяет все данные, перепланирование, Pomodoro, несколько планов, поиск, уведомления и графики, затем тесты и сборки для Android и iPhone. " +
      "Итог: «Маршрут» превращает хаотичное самообучение в понятный план по дням, а данные хранит на собственном сервере без облачных сервисов. Спасибо за внимание, готов ответить на вопросы.");
  }
  const file = path.join(OUT, "Маршрут_защита_концепции.pptx");
  await pres.writeFile({ fileName: file });
  await applyTheme(file, THEME);
  return file;
}

(async () => {
  console.log(await buildFinal());
  console.log(await buildConcept());
})().catch(e => { console.error(e); process.exit(1); });
