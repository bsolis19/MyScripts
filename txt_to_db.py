import sys
import os
import argparse
import pandas as pd

from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine

def parse_args():
    """
    Parse input arguments
    """
    parser = argparse.ArgumentParser(description='Populate environment relational DB from txt file')
    parser.add_argument('filename', nargs=1, help='data file', type=str)
    parser.add_argument('--table', default='txt_to_db', nargs=1, help='table name', type=str)
    parser.add_argument('--delimiter', default='\t', nargs=1, help='token delimiter', type=str)
    parser.add_argument('--dotenvpath', default='.', nargs=1, help='path to .env', type=str)

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    args = parser.parse_args()
    return args

def get_db_engine():
    """
    Create engine for environment database
    """
    DB = os.getenv('DB')
    DB_API = os.getenv('DB_API')
    USERNAME = os.getenv('DB_USERNAME')
    PASSWORD = os.getenv('DB_PASSWORD')
    HOST = os.getenv('DB_HOST')
    DB_NAME = os.getenv('DB_NAME')

    engine_URL = DB + '+' + DB_API + '://' + USERNAME + ':' + PASSWORD + '@' + HOST + '/' + DB_NAME

    try:
        engine = create_engine(engine_URL, echo=True)
    except ValueError:
        print('Error: could not load db')
        sys.exit(1)
    return engine

def load_env():
    """
    Load environment variables
    """
    env_path = str(Path(args.dotenvpath) / '.env')
    try:
        load_dotenv(dotenv_path=env_path)
    except ValueError:
        print('Error: .env not found')

def main():
    global args
    args = parse_args()

    try:
        df = pd.read_table(args.filename[0], sep=args.delimiter)
    except ValueError as e:
        print(e)
        print('Error: Invalid filename')
        sys.exit(1)

    load_env()
    engine = get_db_engine()

    try:
        df.to_sql(args.table, con=engine)
    except ValueError:
        print('Error: could not write to db')
        sys.exit(1)

if __name__ == '__main__':
    main()
