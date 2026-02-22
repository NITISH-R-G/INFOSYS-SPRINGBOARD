import os
import re

directory = 'lib'

for root, dirs, files in os.walk(directory):
    for filename in files:
        if filename.endswith('.dart'):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Replacements
            # 1. replace \$ with ₹
            content = content.replace(r'\$', '₹')
            # 2. replace ($) with (₹)
            content = content.replace(r'($)', '(₹)')
            # 3. replace '$' with '₹'
            content = content.replace(r"'$'", "'₹'")
            # 4. replace "$" with "₹"
            content = content.replace(r'"$"', '"₹"')
            
            # Special case for SLA summary card where it explicitly checks 'INR' : '₹' : '\$'
            # We can just change everything to '₹' since global requirement is INR
            
            with open(filepath, 'w', encoding='utf-8') as file:
                file.write(content)

print('Replacement complete.')
