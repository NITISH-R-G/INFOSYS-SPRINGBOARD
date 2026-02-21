
import sqlite3
import os

DB_PATH = "contract_app.db"

def migrate():
    if not os.path.exists(DB_PATH):
        print(f"Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # Check if column exists
        cursor.execute("PRAGMA table_info(contracts)")
        columns = [info[1] for info in cursor.fetchall()]
        
        if "detailed_analysis" not in columns:
            print("Adding 'detailed_analysis' column...")
            cursor.execute("ALTER TABLE contracts ADD COLUMN detailed_analysis JSON")
            conn.commit()
            print("Migration successful.")
        else:
            print("Column 'detailed_analysis' already exists.")
            
    except Exception as e:
        print(f"Migration failed: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
