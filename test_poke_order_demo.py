import csv
import os

import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.expected_conditions import visibility_of_element_located
from selenium.webdriver.support.ui import Select, WebDriverWait


MY_PATH = os.path.dirname(os.path.realpath(__file__))
HTML_PATH = os.environ.get("POKE_ORDER_HTML", os.path.join(MY_PATH, "poke-order-demo.html"))
TEST_DATA_FOLDER = os.environ.get("POKE_ORDER_DIR", os.path.join(MY_PATH, "test_data"))

ORDER_LAB_LIST_FILES = []
ORDER_QUESTIONS_LIST_FILES = []

for filename in os.listdir(TEST_DATA_FOLDER):
    full_path = os.path.join(TEST_DATA_FOLDER, filename)

    if not os.path.isfile(full_path):
        continue

    if filename.endswith("poke_order_lab_list.csv"):
        ORDER_LAB_LIST_FILES.append(full_path)

    if filename.endswith("poke_order_questions_list.csv"):
        ORDER_QUESTIONS_LIST_FILES.append(full_path)

ORDER_LAB_LIST_FILES.sort()
ORDER_QUESTIONS_LIST_FILES.sort()


def read_csv_rows(path):
    with open(path, "r", encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))


def load_lab_orders(paths):
    orders = []

    for path in paths:
        orders.extend(read_csv_rows(path))

    return orders


def load_question_map(paths):
    question_map = {}

    for path in paths:
        for row in read_csv_rows(path):
            code = row["Poke Order Code"].strip()
            question = row["Poke Question"].strip()
            answers = [value.strip() for value in row["Poke Answer List"].split("|")]

            if code not in question_map:
                question_map[code] = {}

            question_map[code][question] = answers

    return question_map


def get_select_values(select_element) -> list[str]:
    select = Select(select_element)
    return [
        option.text.strip()
        for option in select.options
        if option.get_attribute("value")
    ]


@pytest.fixture(scope="module")
def driver():
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1440,1200")

    driver = webdriver.Chrome(options=options)
    yield driver
    driver.quit()


def test_poke_orders_match_csv_data(driver):
    labs_list = load_lab_orders(ORDER_LAB_LIST_FILES)
    question_map = load_question_map(ORDER_QUESTIONS_LIST_FILES)

    assert os.path.exists(HTML_PATH), f"HTML file not found: {HTML_PATH}"
    for path in ORDER_LAB_LIST_FILES + ORDER_QUESTIONS_LIST_FILES:
        assert os.path.exists(path), f"CSV file not found: {path}"

    driver.get(f"file://{HTML_PATH}")

    order_dropdown = Select(driver.find_element(By.ID, "poke-order-code"))

    for lab in labs_list:
        code = lab["Poke Order Code"].strip()
        order_name = lab["Poke Order Name"].strip()
        expected_questions = question_map[code]
        expected_samples = expected_questions["Samples"]
        expected_specimen = expected_questions["Specimen"]

        order_dropdown.select_by_value(code)

        WebDriverWait(driver, 5).until(
            visibility_of_element_located((By.ID, "samples"))
        )
        WebDriverWait(driver, 5).until(
            visibility_of_element_located((By.ID, "specimen"))
        )

        actual_samples = get_select_values(driver.find_element(By.ID, "samples"))
        actual_specimen = get_select_values(driver.find_element(By.ID, "specimen"))

        assert actual_samples == expected_samples, (
            f"Samples mismatch for {order_name} ({code}). "
            f"Expected {expected_samples}, got {actual_samples}."
        )
        assert actual_specimen == expected_specimen, (
            f"Specimen mismatch for {order_name} ({code}). "
            f"Expected {expected_specimen}, got {actual_specimen}."
        )
