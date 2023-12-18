/* Question Set 1 - Beginner */

/* Q1: Who is the senior most employee based on job title? */
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

/* Q2: Which countries have the most Invoices? */
SELECT billing_country, COUNT(*) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

/* Q3: What are the top 3 values of total invoice? */
SELECT total AS invoice_total
FROM invoice
ORDER BY invoice_total DESC
LIMIT 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. */
/* Write a query that returns one city that has the highest sum of invoice totals.
Return both the city name & sum of all invoice totals */
SELECT billing_city AS CityName, SUM(total) AS TotalInvoiceSum
FROM invoice
GROUP BY billing_city
ORDER BY TotalInvoiceSum DESC
LIMIT 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. */
/* Write a query that returns the person who has spent the most money. */
SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
GROUP BY customer.customer_id
ORDER BY total_spending DESC;

/* Question Set 2 - Moderate */

/* Q1: Write a query to return the email, first name, last name, & Genre of all Rock Music listeners.
Return your list ordered alphabetically by email starting with A. */

/* Method 1*/
SELECT DISTINCT email, first_name, last_name 
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
WHERE track_id IN 
    (SELECT track_id FROM track 
    JOIN genre ON track.genre_id = genre.genre_id
    WHERE genre.name LIKE 'Rock')
ORDER BY email;

/* Method 2 */
SELECT DISTINCT email AS Email, first_name AS FirstName, last_name AS LastName, genre.name AS Genre
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. */
/* Write a query that returns the Artist name and total track count of the top 10 rock bands. */
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

/* Q3: Return all the track names that have a song length longer than the average song length. */
/* Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
SELECT name AS TrackName, Milliseconds
FROM track 
WHERE milliseconds > (SELECT AVG(milliseconds) AS AvgTrackLength FROM track)
ORDER BY milliseconds DESC;

/* Question Set 3 - Advance */

/* Q1: Find out how much amount spent by each customer on artists? */
/* Write a query to return customer name, artist name, and total spent */
WITH best_selling_artist AS (
    SELECT artist.artist_id, artist.name AS artist_name, 
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM invoice_line
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
    GROUP BY artist.artist_id
    ORDER BY 3 DESC
    LIMIT 1
)
SELECT customer.customer_id, customer.first_name, customer.last_name, 
    best_selling_artist.artist_name, SUM(invoice_line.unit_price * invoice_line.quantity) AS amount_spent
FROM invoice
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN best_selling_artist ON best_selling_artist.artist_id = album.artist_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name, best_selling_artist.artist_name
ORDER BY amount_spent DESC;

/* Q2: Most popular music Genre for each country. */
/* Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared, return all Genres. */
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name AS top_genre, 
        ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY customer.country, genre.name
    ORDER BY customer.country ASC, purchases DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;

/* Q3: Determine the customer that has spent the most on music for each country. */
/* Write a query that returns the country along with the top customer and how much they spent. */
/* For countries where the top amount spent is shared, provide all customers who spent this amount. */
WITH customer_with_country AS (
    SELECT customer.customer_id, first_name, last_name, billing_country,
        SUM(total) AS total_spending,
        RANK() OVER (PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RankBySpending
    FROM invoice
    JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY customer.customer_id, first_name, last_name, billing_country
)
SELECT customer_id, first_name, last_name, billing_country, total_spending
FROM customer_with_country
WHERE RankBySpending = 1;
