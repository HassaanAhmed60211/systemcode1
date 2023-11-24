import requests
import csv
import schedule
import time
from flask import Flask, jsonify

app = Flask(__name__)

# CSV file path
csv_file_path = 'top_movies_data.csv'

def update_top_rated_movies():
    global top_rated_movies

    # Your first API request to get top-rated movies
    url_top_rated = "https://imdb8.p.rapidapi.com/title/get-top-rated-movies"
    headers_top_rated = {
        "X-RapidAPI-Key": "f7bbf53fafmsha8dae1569829b38p1f0292jsnc8273ac23a92",
        "X-RapidAPI-Host": "imdb8.p.rapidapi.com"
    }

    response_top_rated = requests.get(url_top_rated, headers=headers_top_rated)
    top_rated_movies = response_top_rated.json()

    # Open the CSV file in write mode to overwrite the existing data
    with open(csv_file_path, 'w', newline='', encoding='utf-8') as csvfile:
        csv_writer = csv.writer(csvfile)

        # Write the CSV header
        csv_writer.writerow(['Title', 'Rating', 'ImageURL'])

        # Iterate over the list of top-rated movies
        for movie in top_rated_movies:
            # Extract the tt value from the id field
            tt_value = movie['id'].split('/title/tt')[1]

            # Your second API request to get details for each movie
            url_movie_details = "https://imdb8.p.rapidapi.com/title/get-details"
            headers_movie_details = {
                "X-RapidAPI-Key": "f7bbf53fafmsha8dae1569829b38p1f0292jsnc8273ac23a92",
                "X-RapidAPI-Host": "imdb8.p.rapidapi.com"
            }
            querystring_movie_details = {"tconst": f"tt{tt_value}"}

            response_movie_details = requests.get(url_movie_details, headers=headers_movie_details, params=querystring_movie_details)
            movie_details = response_movie_details.json()

            # Extract the desired information
            title = movie_details.get('title', 'N/A')
            rating = movie.get('chartRating', 'N/A')

            # Extract the image information
            image_info = movie_details.get('image', {})
            imageUrl = image_info.get('url', 'N/A')

            # Write the movie details to the CSV file
            csv_writer.writerow([title, rating, imageUrl])

            print(f"Data for '{title}' has been added to {csv_file_path}")

def read_csv():
    data = []
    with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            data.append(row)
    return data

@app.route('/top250movies', methods=['GET'])
def get_movies():
    movies_data = read_csv()
    return jsonify(movies_data)

# Schedule the update task to run every 24 hours
schedule.every(24).hours.do(update_top_rated_movies)

if __name__ == '__main__':
    # Run the Flask app
    app.run(debug=True)

    # Run the scheduled tasks in a separate thread
    while True:
        schedule.run_pending()
        time.sleep(1)




























# import requests
# import csv

# # Your first API request to get top-rated movies
# url_top_rated = "https://imdb8.p.rapidapi.com/title/get-top-rated-movies"
# headers_top_rated = {
#     "X-RapidAPI-Key": "314a043327mshda107b2f95a84c8p10d4f0jsn7e9835bf3480",
#     "X-RapidAPI-Host": "imdb8.p.rapidapi.com"
# }

# response_top_rated = requests.get(url_top_rated, headers=headers_top_rated)
# top_rated_movies = response_top_rated.json()

# # CSV file path
# csv_file_path = 'top_movies_data.csv'

# # Open the CSV file in append mode
# with open(csv_file_path, 'a', newline='', encoding='utf-8') as csvfile:
#     csv_writer = csv.writer(csvfile)

#     # Iterate over the list of top-rated movies
#     for movie in top_rated_movies:
#         # Extract the tt value from the id field
#         tt_value = movie['id'].split('/title/tt')[1]

#         # Your second API request to get details for each movie
#         url_movie_details = "https://imdb8.p.rapidapi.com/title/get-details"
#         headers_movie_details = {
#             "X-RapidAPI-Key": "314a043327mshda107b2f95a84c8p10d4f0jsn7e9835bf3480",
#             "X-RapidAPI-Host": "imdb8.p.rapidapi.com"
#         }
#         querystring_movie_details = {"tconst": f"tt{tt_value}"}

#         response_movie_details = requests.get(url_movie_details, headers=headers_movie_details, params=querystring_movie_details)
#         movie_details = response_movie_details.json()

#         # Extract the desired information
#         title = movie_details.get('title', 'N/A')
#         rating = movie.get('chartRating', 'N/A')

#         # Extract the image information
#         image_info = movie_details.get('image', {})
#         imageUrl = image_info.get('url', 'N/A')

#         # Write the movie details to the CSV file
#         csv_writer.writerow([title,rating, imageUrl])

#         print(f"Data for '{title}' has been added to {csv_file_path}")