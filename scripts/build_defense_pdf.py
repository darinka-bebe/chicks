#!/usr/bin/env python3
"""Export Chicks defense presentation to PDF."""

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
)
from reportlab.graphics.shapes import Drawing, Rect, String

OUTPUT_PATHS = [
    "/Users/natala/Downloads/защита_Chicks.pdf",
    "/Users/natala/Desktop/защита_Chicks.pdf",
]
PAGE_W, PAGE_H = landscape((10 * inch, 7.5 * inch))

FONT = "ArialUni"
FONT_BOLD = "ArialUni-Bold"


def register_fonts():
    regular = "/System/Library/Fonts/Supplemental/Arial.ttf"
    bold = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
    pdfmetrics.registerFont(TTFont(FONT, regular))
    pdfmetrics.registerFont(TTFont(FONT_BOLD, bold))


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            fontName=FONT_BOLD,
            fontSize=22,
            leading=28,
            alignment=TA_CENTER,
            spaceAfter=12,
        ),
        "subtitle": ParagraphStyle(
            "subtitle",
            fontName=FONT,
            fontSize=14,
            leading=20,
            alignment=TA_CENTER,
            spaceAfter=8,
        ),
        "heading": ParagraphStyle(
            "heading",
            fontName=FONT_BOLD,
            fontSize=20,
            leading=24,
            spaceAfter=10,
        ),
        "body": ParagraphStyle(
            "body",
            fontName=FONT,
            fontSize=11,
            leading=15,
            spaceAfter=6,
        ),
        "caption": ParagraphStyle(
            "caption",
            fontName=FONT,
            fontSize=9,
            leading=11,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#444444"),
            fontStyle="italic",
        ),
        "placeholder": ParagraphStyle(
            "placeholder",
            fontName=FONT,
            fontSize=10,
            leading=12,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#666666"),
        ),
    }


def screenshot_box(canvas, x, y, w, h, hint, caption, st):
    canvas.saveState()
    canvas.setFillColor(colors.HexColor("#F2F2F2"))
    canvas.setStrokeColor(colors.HexColor("#999999"))
    canvas.setLineWidth(1)
    canvas.rect(x, y, w, h, fill=1, stroke=1)
    canvas.setFillColor(colors.HexColor("#666666"))
    canvas.setFont(FONT, 10)
    cx = x + w / 2
    canvas.drawCentredString(cx, y + h / 2 + 6, "[ Скриншот ]")
    if hint:
        canvas.setFont(FONT, 8)
        canvas.drawCentredString(cx, y + h / 2 - 10, hint)
    canvas.setFont(FONT, 9)
    canvas.setFillColor(colors.HexColor("#444444"))
    canvas.drawCentredString(cx, y - 14, caption)
    canvas.restoreState()


def draw_slide_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont(FONT, 8)
    canvas.setFillColor(colors.grey)
    canvas.drawRightString(PAGE_W - 0.4 * inch, 0.25 * inch, f"{doc.page}")
    canvas.restoreState()


def build_pdf():
    register_fonts()
    st = styles()

    doc = BaseDocTemplate(
        OUTPUT,
        pagesize=(PAGE_W, PAGE_H),
        leftMargin=0.45 * inch,
        rightMargin=0.45 * inch,
        topMargin=0.4 * inch,
        bottomMargin=0.35 * inch,
    )

    frame = Frame(
        doc.leftMargin,
        doc.bottomMargin,
        doc.width,
        doc.height,
        id="normal",
    )
    doc.addPageTemplates(
        [PageTemplate(id="slide", frames=[frame], onPage=draw_slide_footer)]
    )

    story = []

    def add_heading(text):
        story.append(Paragraph(text, st["heading"]))
        story.append(Spacer(1, 6))

    def add_body(text):
        for line in text.strip().split("\n"):
            if line.strip():
                story.append(Paragraph(line, st["body"]))

    # Slide 1
    story.append(Paragraph(
        "Тема: Разработка мобильного приложения персонального ИИ-стилиста «Chicks»",
        st["title"],
    ))
    story.append(Spacer(1, 20))
    story.append(Paragraph("Выполнила: ФИО", st["subtitle"]))
    story.append(Paragraph("Группа: ___", st["subtitle"]))
    story.append(Spacer(1, 16))
    story.append(Paragraph("Научный руководитель: Эмирова З.М.", st["subtitle"]))
    story.append(PageBreak())

    # Slide 2
    add_heading("АКТУАЛЬНОСТЬ")
    add_body(
        """• Ежедневный выбор одежды отнимает время и вызывает стресс («не знаю, что надеть»).
• Услуги профессионального стилиста дороги и недоступны большинству пользователей.
• Покупки «наугад» приводят к вещам, которые не сочетаются с гардеробом.
• Рост популярности ИИ открывает возможность персональных fashion-рекомендаций в смартфоне 24/7.
• Спрос на мобильные fashion-приложения с учётом типа фигуры, цветотипа и личного гардероба растёт.

<b>Вывод:</b> разработка приложения, объединяющего цифровой гардероб, анализ стиля и ИИ-консультанта, является актуальной."""
    )
    story.append(PageBreak())

    # Slide 3
    add_heading("ЦЕЛЬ — ЗАДАЧИ — ОБЪЕКТ — ПРЕДМЕТ")
    add_body(
        """<b>ЦЕЛЬ</b><br/>
Разработать кроссплатформенное мобильное приложение «Chicks» для персональных рекомендаций по стилю на основе цифрового гардероба и технологий искусственного интеллекта.

<b>ЗАДАЧИ</b><br/>
1. Проанализировать предметную область и существующие fashion-приложения.<br/>
2. Сформировать функциональные и нефункциональные требования к системе.<br/>
3. Спроектировать архитектуру приложения (Flutter, BLoC, GoRouter).<br/>
4. Реализовать модуль цифрового гардероба с распознаванием одежды по фото (OpenAI Vision).<br/>
5. Реализовать чат с ИИ-стилистом (OpenAI GPT-4o-mini) с учётом гардероба, погоды и контекста.<br/>
6. Реализовать анализ стиля, онбординг (цветотип, тип фигуры) и мультиязычность (RU / EN / KK).<br/>
7. Провести тестирование и оценить результаты разработки.

<b>ОБЪЕКТ исследования</b> — процесс создания мобильных приложений в сфере fashion-tech.<br/>
<b>ПРЕДМЕТ исследования</b> — методы и средства разработки ИИ-ориентированного приложения для подбора образов и управления гардеробом."""
    )
    story.append(PageBreak())

    # Slide 4
    add_heading("ГЛАВА 1. Теоретические основы и анализ предметной области")
    add_body(
        """1.1. Понятие персонального стайлинга и цифрового гардероба.

1.2. Обзор аналогов: Pinterest, Stylebook, Whering, ChatGPT и др.<br/>
→ отличие Chicks: гардероб + ИИ-чат + анализ стиля + учёт цветотипа и фигуры в одном приложении.

1.3. Технологии разработки:<br/>
Flutter / Dart — кроссплатформенный UI (Android, iOS);<br/>
BLoC / Cubit — управление состоянием; GoRouter — навигация;<br/>
Firebase (Auth, Firestore, Storage) — авторизация и облачное хранение;<br/>
OpenAI API — GPT-4o-mini (чат) и Vision (распознавание одежды);<br/>
Hive / SharedPreferences — локальное хранение.

1.4. Требования к системе: функциональные (гардероб, чат, профиль, избранное, история) и нефункциональные (производительность, безопасность API-ключей, локализация)."""
    )
    story.append(PageBreak())

    # Slide 5
    add_heading("ГЛАВА 2. Практическая реализация приложения «Chicks»")
    add_body(
        """2.1. Архитектура: feature-first — features/ (UI), core/ (сервисы, роутинг), data/ (модели, репозитории).

2.2. Реализованные модули:<br/>
<b>Гардероб</b> — добавление вещей по фото, AI-распознавание, категории, фильтры, избранное.<br/>
<b>ИИ-чат</b> — подбор образов из гардероба, учёт погоды, настроения, повода.<br/>
<b>Анализ стиля</b> — локальные инсайты: баланс категорий, пробелы, рекомендации.<br/>
<b>Профиль</b> — аватар, цветотип, фигура, частые настроения и поводы.<br/>
<b>Избранное и история</b> — сохранённые образы и прошлые рекомендации.<br/>
<b>Локализация</b> — русский, английский, казахский.

2.3. Стек: Flutter 3.10+, Dart 3.0+, OpenAI, Firebase, geolocator (погода).<br/>
2.4. Результат: рабочее приложение (APK / iOS), версия 1.0.0+1."""
    )
    story.append(PageBreak())

    # Slide 6 continuation
    add_heading("ГЛАВА 2 (продолжение)")
    story.append(Paragraph("Скриншоты интерфейса — см. ниже на странице.", st["body"]))
    story.append(PageBreak())

    # Slide 7 demo
    add_heading("ДЕМОНСТРАЦИЯ ИНТЕРФЕЙСА")
    story.append(Paragraph(
        "Дополнительные экраны приложения для демонстрации функциональности.",
        st["body"],
    ))
    story.append(PageBreak())

    # Slide 8 conclusion
    add_heading("ЗАКЛЮЧЕНИЕ")
    add_body(
        """В ходе работы:<br/>
• проанализирована предметная область fashion-tech и обоснована актуальность темы;<br/>
• спроектирована и реализована архитектура мобильного приложения «Chicks»;<br/>
• создан модуль цифрового гардероба с AI-распознаванием вещей по фотографии;<br/>
• реализован интеллектуальный чат-стилист с учётом гардероба, погоды и профиля пользователя;<br/>
• добавлены анализ стиля, онбординг, избранное, история образов и поддержка трёх языков;<br/>
• проведено тестирование на Android и iOS.

<b>Практическая значимость:</b> приложение помогает пользователям быстрее выбирать образы, рациональнее использовать гардероб и получать персональные рекомендации без услуг живого стилиста.

<b>Перспективы развития:</b> подписка, интеграция с магазинами, push-уведомления, улучшение offline-режима.

<b>Спасибо за внимание!</b><br/>
Готова ответить на вопросы."""
    )

    # Custom canvas overlay for screenshot placeholders per page
    placeholders_by_page = {
        1: [
            (5.8 * inch, 1.0 * inch, 3.6 * inch, 2.4 * inch,
             "Splash или Главная с приветствием",
             "Рис. 1. Мобильное приложение «Chicks» — персональный ИИ-стилист"),
        ],
        2: [
            (0.5 * inch, 3.8 * inch, 4.3 * inch, 1.8 * inch,
             "Чат со стилистом",
             "Рис. 2. ИИ-стилист помогает выбрать образ за несколько секунд"),
            (5.0 * inch, 3.8 * inch, 4.3 * inch, 1.8 * inch,
             "Гардероб — сетка вещей",
             "Рис. 3. Цифровой гардероб пользователя в приложении"),
        ],
        3: [
            (6.0 * inch, 0.8 * inch, 3.5 * inch, 5.8 * inch,
             "Главная: погода, инсайты, быстрые идеи",
             "Рис. 4. Основные модули приложения «Chicks» на главном экране"),
        ],
        4: [
            (5.5 * inch, 1.0 * inch, 4.0 * inch, 1.3 * inch,
             "Квиз цветотипа",
             "Рис. 5. Онбординг: определение цветотипа пользователя"),
            (5.5 * inch, 2.6 * inch, 4.0 * inch, 1.3 * inch,
             "Квиз типа фигуры",
             "Рис. 6. Онбординг: определение типа фигуры"),
            (5.5 * inch, 4.2 * inch, 4.0 * inch, 1.3 * inch,
             "Профиль: цветотип и фигура",
             "Рис. 7. Сохранённые параметры стиля в профиле"),
        ],
        5: [
            (0.4 * inch, 3.5 * inch, 4.4 * inch, 1.5 * inch, "Гардероб",
             "Рис. 8. Экран цифрового гардероба"),
            (5.0 * inch, 3.5 * inch, 4.4 * inch, 1.5 * inch, "Добавление вещи",
             "Рис. 9. Распознавание одежды (OpenAI Vision)"),
            (0.4 * inch, 5.3 * inch, 4.4 * inch, 1.5 * inch, "Карточка вещи",
             "Рис. 10. Детальная карточка элемента гардероба"),
            (5.0 * inch, 5.3 * inch, 4.4 * inch, 1.5 * inch, "Чат с образом",
             "Рис. 11. ИИ-стилист: подбор образа из гардероба"),
        ],
        6: [
            (0.8 * inch, 2.0 * inch, 4.0 * inch, 3.2 * inch,
             "Главная: погода и инсайты",
             "Рис. 12. Персональные инсайты и учёт погоды"),
            (5.2 * inch, 2.0 * inch, 4.0 * inch, 3.2 * inch,
             "Инсайты гардероба или Избранное",
             "Рис. 13. Анализ гардероба / сохранённые образы"),
        ],
        7: [
            (0.5 * inch, 1.2 * inch, 4.3 * inch, 2.2 * inch,
             "Экран входа (Google Sign-In)",
             "Рис. 15. Авторизация пользователя"),
            (5.0 * inch, 1.2 * inch, 4.3 * inch, 2.2 * inch,
             "Быстрые подсказки в чате",
             "Рис. 16. Контекстные подсказки для стилиста"),
            (0.5 * inch, 3.8 * inch, 4.3 * inch, 2.2 * inch,
             "Фильтры гардероба",
             "Рис. 17. Фильтрация элементов гардероба"),
            (5.0 * inch, 3.8 * inch, 4.3 * inch, 2.2 * inch,
             "Профиль: настройки и статистика",
             "Рис. 18. Профиль пользователя"),
        ],
        8: [
            (6.0 * inch, 0.9 * inch, 3.5 * inch, 5.5 * inch,
             "Чат с образом или Главная целиком",
             "Рис. 14. Итоговый вид приложения «Chicks»"),
        ],
    }

    class OverlayDoc(BaseDocTemplate):
        def afterPage(self):
            page = self.page
            if page in placeholders_by_page:
                for x, y, w, h, hint, cap in placeholders_by_page[page]:
                    screenshot_box(self.canv, x, y, w, h, hint, cap, st)

    # Rebuild with overlay - use simpler approach: single pass with onPage callback
    class SlideDoc(BaseDocTemplate):
        def __init__(self, *args, **kwargs):
            self._page_num = 0
            super().__init__(*args, **kwargs)

        def handle_pageBegin(self):
            self._page_num += 1
            super().handle_pageBegin()

        def handle_pageEnd(self):
            page = self._page_num
            if page in placeholders_by_page:
                for x, y, w, h, hint, cap in placeholders_by_page[page]:
                    screenshot_box(self.canv, x, y, w, h, hint, cap, st)
            super().handle_pageEnd()

    doc2 = SlideDoc(
        OUTPUT,
        pagesize=(PAGE_W, PAGE_H),
        leftMargin=0.45 * inch,
        rightMargin=0.45 * inch,
        topMargin=0.4 * inch,
        bottomMargin=0.35 * inch,
    )
    doc2.addPageTemplates(
        [PageTemplate(id="slide", frames=[frame], onPage=draw_slide_footer)]
    )
    doc2.build(story)
    print(f"Saved: {OUTPUT}")


if __name__ == "__main__":
    build_pdf()
