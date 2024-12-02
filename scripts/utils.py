import os
from dotenv import load_dotenv, find_dotenv
import pandas as pd
from sqlalchemy import create_engine, text
import random
import csv
import json

import numpy as np
import config

import yaml

load_dotenv(find_dotenv())
engine = create_engine(f'postgresql://{config.db_username}:{config.db_password}@{config.db_host}:{config.db_port}/{config.db_name}')
connection = engine.connect()