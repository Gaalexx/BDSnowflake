CREATE TEMP TABLE mock_data_clean AS
SELECT
    id AS raw_id,
    row_key AS row_raw_key,
    sale_date,
    sale_quantity,
    sale_total_price,
    product_price AS source_unit_price,
    product_quantity AS source_product_quantity,
    customer_first_name,
    customer_last_name,
    customer_age,
    customer_email,
    customer_country,
    customer_postal_code,
    customer_pet_type,
    customer_pet_name,
    customer_pet_breed,
    seller_first_name,
    seller_last_name,
    seller_email,
    seller_country,
    seller_postal_code,
    store_name,
    store_location,
    store_city,
    store_state,
    store_country,
    store_phone,
    store_email,
    supplier_name,
    supplier_contact,
    supplier_email,
    supplier_phone,
    supplier_address,
    supplier_city,
    supplier_country,
    product_name,
    product_category,
    pet_category,
    product_price,
    product_quantity,
    product_weight,
    product_color,
    product_size,
    product_brand,
    product_material,
    product_description,
    product_rating,
    product_reviews,
    product_release_date,
    product_expiry_date
FROM mock_data_raw;



CREATE TABLE dim_customer (
    customer_key uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_email text NOT NULL UNIQUE,
    first_name text,
    last_name text,
    age integer,
    country text,
    postal_code text,
    pet_type text,
    pet_name text,
    pet_breed text
);

CREATE TABLE dim_seller (
    seller_key uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_email text NOT NULL UNIQUE,
    first_name text,
    last_name text,
    country text,
    postal_code text
);

CREATE TABLE dim_store (
    store_key uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    store_email text NOT NULL UNIQUE,
    store_name text,
    location text,
    city text,
    state text,
    country text,
    phone text
);

CREATE TABLE dim_supplier (
    supplier_key uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_email text NOT NULL UNIQUE,
    supplier_name text,
    contact_name text,
    phone text,
    address text,
    city text,
    country text
);

CREATE TABLE dim_product (
    product_key uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    product_name text,
    product_category text,
    pet_category text,
    unit_price numeric(10, 2),
    available_quantity integer,
    weight numeric(10, 2),
    color text,
    size text,
    brand text,
    material text,
    description text,
    rating numeric(3, 1),
    reviews integer,
    release_date date,
    expiry_date date
);

CREATE TABLE fact_sales (
    sales_key uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_raw_id bigint NOT NULL,
    source_raw_key UUID NOT NULL,
    customer_key uuid NOT NULL REFERENCES dim_customer(customer_key),
    seller_key uuid NOT NULL REFERENCES dim_seller(seller_key),
    store_key uuid NOT NULL REFERENCES dim_store(store_key),
    supplier_key uuid NOT NULL REFERENCES dim_supplier(supplier_key),
    product_key uuid NOT NULL REFERENCES dim_product(product_key),
    sale_quantity integer NOT NULL,
    sale_total_price numeric(10, 2) NOT NULL,
    source_unit_price numeric(10, 2),
    source_product_quantity integer,
    sale_date date NOT NULL
);

CREATE INDEX idx_fact_sales_sale_date ON fact_sales (sale_date);
CREATE INDEX idx_fact_sales_customer_key ON fact_sales (customer_key);
CREATE INDEX idx_fact_sales_seller_key ON fact_sales (seller_key);
CREATE INDEX idx_fact_sales_store_key ON fact_sales (store_key);
CREATE INDEX idx_fact_sales_supplier_key ON fact_sales (supplier_key);
CREATE INDEX idx_fact_sales_product_key ON fact_sales (product_key);


INSERT INTO dim_customer (
    customer_email,
    first_name,
    last_name,
    age,
    country,
    postal_code,
    pet_type,
    pet_name,
    pet_breed
)
SELECT DISTINCT
    customer_email,
    customer_first_name,
    customer_last_name,
    customer_age,
    customer_country,
    customer_postal_code,
    customer_pet_type,
    customer_pet_name,
    customer_pet_breed
FROM mock_data_clean
WHERE customer_email IS NOT NULL;

INSERT INTO dim_seller (
    seller_email,
    first_name,
    last_name,
    country,
    postal_code
)
SELECT DISTINCT
    seller_email,
    seller_first_name,
    seller_last_name,
    seller_country,
    seller_postal_code
FROM mock_data_clean
WHERE seller_email IS NOT NULL;

INSERT INTO dim_store (
    store_email,
    store_name,
    location,
    city,
    state,
    country,
    phone
)
SELECT DISTINCT
    store_email,
    store_name,
    store_location,
    store_city,
    store_state,
    store_country,
    store_phone
FROM mock_data_clean
WHERE store_email IS NOT NULL;

INSERT INTO dim_supplier (
    supplier_email,
    supplier_name,
    contact_name,
    phone,
    address,
    city,
    country
)
SELECT DISTINCT
    supplier_email,
    supplier_name,
    supplier_contact,
    supplier_phone,
    supplier_address,
    supplier_city,
    supplier_country
FROM mock_data_clean
WHERE supplier_email IS NOT NULL;

INSERT INTO dim_product (
    product_name,
    product_category,
    pet_category,
    unit_price,
    available_quantity,
    weight,
    color,
    size,
    brand,
    material,
    description,
    rating,
    reviews,
    release_date,
    expiry_date
)
SELECT DISTINCT
    product_name,
    product_category,
    pet_category,
    product_price,
    product_quantity,
    product_weight,
    product_color,
    product_size,
    product_brand,
    product_material,
    product_description,
    product_rating,
    product_reviews,
    product_release_date,
    product_expiry_date
FROM mock_data_clean;

INSERT INTO fact_sales (
    source_raw_id,
    source_raw_key,
    customer_key,
    seller_key,
    store_key,
    supplier_key,
    product_key,
    sale_quantity,
    sale_total_price,
    source_unit_price,
    source_product_quantity,
    sale_date
)
SELECT
    src.raw_id,
    src.row_raw_key,
    dc.customer_key,
    ds.seller_key,
    dst.store_key,
    dsp.supplier_key,
    dp.product_key,
    src.sale_quantity,
    src.sale_total_price,
    src.source_unit_price,
    src.source_product_quantity,
    src.sale_date
FROM mock_data_clean AS src
JOIN dim_customer AS dc
    ON dc.customer_email = src.customer_email
JOIN dim_seller AS ds
    ON ds.seller_email = src.seller_email
JOIN dim_store AS dst
    ON dst.store_email = src.store_email
JOIN dim_supplier AS dsp
    ON dsp.supplier_email = src.supplier_email
JOIN dim_product AS dp
    ON dp.product_name IS NOT DISTINCT FROM src.product_name
    AND dp.product_category IS NOT DISTINCT FROM src.product_category
    AND dp.pet_category IS NOT DISTINCT FROM src.pet_category
    AND dp.unit_price IS NOT DISTINCT FROM src.product_price
    AND dp.available_quantity IS NOT DISTINCT FROM src.product_quantity
    AND dp.weight IS NOT DISTINCT FROM src.product_weight
    AND dp.color IS NOT DISTINCT FROM src.product_color
    AND dp.size IS NOT DISTINCT FROM src.product_size
    AND dp.brand IS NOT DISTINCT FROM src.product_brand
    AND dp.material IS NOT DISTINCT FROM src.product_material
    AND dp.description IS NOT DISTINCT FROM src.product_description
    AND dp.rating IS NOT DISTINCT FROM src.product_rating
    AND dp.reviews IS NOT DISTINCT FROM src.product_reviews
    AND dp.release_date IS NOT DISTINCT FROM src.product_release_date
    AND dp.expiry_date IS NOT DISTINCT FROM src.product_expiry_date;