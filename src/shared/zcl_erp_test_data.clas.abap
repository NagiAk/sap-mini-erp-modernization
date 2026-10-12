CLASS zcl_erp_test_data DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES tt_products TYPE STANDARD TABLE OF zerp_product WITH EMPTY KEY.

    DATA mv_today    TYPE d.
    DATA mt_products TYPE tt_products.

    METHODS clear_all_tables.
    METHODS create_config       RETURNING VALUE(rv_count) TYPE i.
    METHODS create_customers    RETURNING VALUE(rv_count) TYPE i.
    METHODS create_suppliers    RETURNING VALUE(rv_count) TYPE i.
    METHODS create_products     RETURNING VALUE(rv_count) TYPE i.
    METHODS create_stock        RETURNING VALUE(rv_count) TYPE i.
    METHODS create_sales_orders RETURNING VALUE(rv_count) TYPE i.
ENDCLASS.


CLASS zcl_erp_test_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    mv_today = cl_abap_context_info=>get_system_date( ).

    clear_all_tables( ).
    out->write( 'All ZERP tables cleared.' ).

    out->write( |Config entries: { create_config( ) }| ).
    out->write( |Customers:      { create_customers( ) }| ).
    out->write( |Suppliers:      { create_suppliers( ) }| ).
    out->write( |Products:       { create_products( ) }| ).
    out->write( |Stock records:  { create_stock( ) }| ).
    out->write( |Sales orders:   { create_sales_orders( ) }| ).

    COMMIT WORK.
    out->write( 'Test data created successfully.' ).
  ENDMETHOD.


  METHOD clear_all_tables.
    " Master data and configuration
    DELETE FROM zerp_config.
    DELETE FROM zerp_customer.
    DELETE FROM zerp_supplier.
    DELETE FROM zerp_product.
    DELETE FROM zerp_stock.
    DELETE FROM zerp_stock_move.
    " Sales documents
    DELETE FROM zerp_so_h.
    DELETE FROM zerp_so_i.
    DELETE FROM zerp_dlv_h.
    DELETE FROM zerp_dlv_i.
    DELETE FROM zerp_inv_h.
    DELETE FROM zerp_inv_i.
    DELETE FROM zerp_payment.
    DELETE FROM zerp_dunning.
    " Purchasing documents
    DELETE FROM zerp_preq.
    DELETE FROM zerp_po_h.
    DELETE FROM zerp_po_i.
    DELETE FROM zerp_gr_h.
    DELETE FROM zerp_gr_i.
    DELETE FROM zerp_sinv_h.
    DELETE FROM zerp_sinv_i.
    DELETE FROM zerp_spayment.
  ENDMETHOD.


  METHOD create_config.
    DATA lt_config TYPE STANDARD TABLE OF zerp_config WITH EMPTY KEY.

    lt_config = VALUE #(
      ( config_key = 'TAX_RATE'        config_value = '20'  description = 'VAT rate in percent' )
      ( config_key = 'DISCOUNT_A'      config_value = '10'  description = 'Discount for class A customers (%)' )
      ( config_key = 'DISCOUNT_B'      config_value = '5'   description = 'Discount for class B customers (%)' )
      ( config_key = 'DISCOUNT_C'      config_value = '0'   description = 'Discount for class C customers (%)' )
      ( config_key = 'QTY_DISC_LIMIT'  config_value = '100' description = 'Quantity above which extra discount applies' )
      ( config_key = 'QTY_DISC_PCT'    config_value = '3'   description = 'Extra quantity discount (%)' )
      ( config_key = 'DUNNING_DAYS_1'  config_value = '7'   description = 'Days overdue for dunning level 1' )
      ( config_key = 'DUNNING_DAYS_2'  config_value = '21'  description = 'Days overdue for dunning level 2' )
      ( config_key = 'DUNNING_DAYS_3'  config_value = '45'  description = 'Days overdue for dunning level 3' )
      ( config_key = 'DUNNING_FEE_2'   config_value = '10'  description = 'Fee for dunning level 2 (EUR)' )
      ( config_key = 'DUNNING_FEE_3'   config_value = '25'  description = 'Fee for dunning level 3 (EUR)' )
      ( config_key = 'MATCH_PRICE_TOL' config_value = '2'   description = 'Three-way match price tolerance (%)' ) ).

    INSERT zerp_config FROM TABLE @lt_config.
    rv_count = lines( lt_config ).
  ENDMETHOD.


  METHOD create_customers.
    DATA lt_customers TYPE STANDARD TABLE OF zerp_customer WITH EMPTY KEY.

    lt_customers = VALUE #( currency = 'EUR' created_on = mv_today
      ( customer_id = 'C0001' name = 'Atlas Distribution'  city = 'Casablanca' country = 'MA' discount_class = 'A' credit_limit = 50000 payment_days = 30 )
      ( customer_id = 'C0002' name = 'Fes Office Supplies' city = 'Fes'        country = 'MA' discount_class = 'B' credit_limit = 20000 payment_days = 45 )
      ( customer_id = 'C0003' name = 'Lyon Tech Services'  city = 'Lyon'       country = 'FR' discount_class = 'A' credit_limit = 80000 payment_days = 30 )
      ( customer_id = 'C0004' name = 'Marseille Bureau'    city = 'Marseille'  country = 'FR' discount_class = 'C' credit_limit = 5000  payment_days = 60 )
      ( customer_id = 'C0005' name = 'Rabat Digital'       city = 'Rabat'      country = 'MA' discount_class = 'B' credit_limit = 15000 payment_days = 30 )
      ( customer_id = 'C0006' name = 'Paris Startup Hub'   city = 'Paris'      country = 'FR' discount_class = 'C' credit_limit = 10000 payment_days = 45 )
      ( customer_id = 'C0007' name = 'Tanger Logistics'    city = 'Tanger'     country = 'MA' discount_class = 'A' credit_limit = 40000 payment_days = 60 )
      ( customer_id = 'C0008' name = 'Nantes Consulting'   city = 'Nantes'     country = 'FR' discount_class = 'C' credit_limit = 3000  payment_days = 30 ) ).

    INSERT zerp_customer FROM TABLE @lt_customers.
    rv_count = lines( lt_customers ).
  ENDMETHOD.


  METHOD create_suppliers.
    DATA lt_suppliers TYPE STANDARD TABLE OF zerp_supplier WITH EMPTY KEY.

    lt_suppliers = VALUE #( currency = 'EUR' created_on = mv_today
      ( supplier_id = 'S0001' name = 'TechSource Europe' city = 'Amsterdam' country = 'NL' payment_days = 30 discount_days = 10 discount_pct = 2 )
      ( supplier_id = 'S0002' name = 'DisplayPro GmbH'   city = 'Munich'    country = 'DE' payment_days = 45 discount_days = 14 discount_pct = 2 )
      ( supplier_id = 'S0003' name = 'Peripheral World'  city = 'Lille'     country = 'FR' payment_days = 30 discount_days = 0  discount_pct = 0 )
      ( supplier_id = 'S0004' name = 'ErgoFurniture SA'  city = 'Barcelona' country = 'ES' payment_days = 60 discount_days = 10 discount_pct = 3 ) ).

    INSERT zerp_supplier FROM TABLE @lt_suppliers.
    rv_count = lines( lt_suppliers ).
  ENDMETHOD.


  METHOD create_products.
    mt_products = VALUE #( currency = 'EUR' base_unit = 'ST'
      ( product_id = 'P0001' description = 'Laptop Pro 14'         category = 'COMPUTERS'   sales_price = 1200 purchase_price = 850 reorder_point = 10  reorder_qty = 30  supplier_id = 'S0001' )
      ( product_id = 'P0002' description = 'Monitor 27 inch'       category = 'DISPLAYS'    sales_price = 320  purchase_price = 210 reorder_point = 15  reorder_qty = 40  supplier_id = 'S0002' )
      ( product_id = 'P0003' description = 'Mechanical Keyboard'   category = 'PERIPHERALS' sales_price = 95   purchase_price = 55  reorder_point = 30  reorder_qty = 100 supplier_id = 'S0003' )
      ( product_id = 'P0004' description = 'Wireless Mouse'        category = 'PERIPHERALS' sales_price = 35   purchase_price = 18  reorder_point = 50  reorder_qty = 200 supplier_id = 'S0003' )
      ( product_id = 'P0005' description = 'Docking Station'       category = 'COMPUTERS'   sales_price = 180  purchase_price = 120 reorder_point = 10  reorder_qty = 25  supplier_id = 'S0001' )
      ( product_id = 'P0006' description = 'Ergonomic Office Chair' category = 'FURNITURE'  sales_price = 260  purchase_price = 160 reorder_point = 8   reorder_qty = 20  supplier_id = 'S0004' )
      ( product_id = 'P0007' description = 'Standing Desk'         category = 'FURNITURE'   sales_price = 540  purchase_price = 360 reorder_point = 5   reorder_qty = 15  supplier_id = 'S0004' )
      ( product_id = 'P0008' description = 'Noise-Cancel Headset'  category = 'AUDIO'       sales_price = 120  purchase_price = 70  reorder_point = 20  reorder_qty = 60  supplier_id = 'S0002' )
      ( product_id = 'P0009' description = 'HD Webcam'             category = 'PERIPHERALS' sales_price = 75   purchase_price = 40  reorder_point = 20  reorder_qty = 50  supplier_id = 'S0002' )
      ( product_id = 'P0010' description = 'USB-C Cable 2m'        category = 'ACCESSORIES' sales_price = 12   purchase_price = 4   reorder_point = 100 reorder_qty = 500 supplier_id = 'S0003' ) ).

    INSERT zerp_product FROM TABLE @mt_products.
    rv_count = lines( mt_products ).
  ENDMETHOD.


  METHOD create_stock.
    DATA lt_stock TYPE STANDARD TABLE OF zerp_stock WITH EMPTY KEY.

    " P0002, P0005, P0007 and P0010 are below their reorder point on purpose
    lt_stock = VALUE #( base_unit = 'ST' last_changed = mv_today
      ( product_id = 'P0001' quantity = 25 )
      ( product_id = 'P0002' quantity = 12 )
      ( product_id = 'P0003' quantity = 150 )
      ( product_id = 'P0004' quantity = 400 )
      ( product_id = 'P0005' quantity = 6 )
      ( product_id = 'P0006' quantity = 30 )
      ( product_id = 'P0007' quantity = 3 )
      ( product_id = 'P0008' quantity = 45 )
      ( product_id = 'P0009' quantity = 60 )
      ( product_id = 'P0010' quantity = 5 ) ).

    INSERT zerp_stock FROM TABLE @lt_stock.
    rv_count = lines( lt_stock ).
  ENDMETHOD.


  METHOD create_sales_orders.
    DATA lt_head TYPE STANDARD TABLE OF zerp_so_h WITH EMPTY KEY.
    DATA lt_item TYPE STANDARD TABLE OF zerp_so_i WITH EMPTY KEY.

    lt_head = VALUE #( status = 'N' currency = 'EUR' created_by = sy-uname
      ( order_id = 'SO00000001' customer_id = 'C0001' order_date = mv_today - 12 created_on = mv_today - 12 )
      ( order_id = 'SO00000002' customer_id = 'C0002' order_date = mv_today - 10 created_on = mv_today - 10 )
      ( order_id = 'SO00000003' customer_id = 'C0003' order_date = mv_today - 9  created_on = mv_today - 9 )
      ( order_id = 'SO00000004' customer_id = 'C0004' order_date = mv_today - 8  created_on = mv_today - 8 )
      ( order_id = 'SO00000005' customer_id = 'C0005' order_date = mv_today - 7  created_on = mv_today - 7 )
      ( order_id = 'SO00000006' customer_id = 'C0006' order_date = mv_today - 6  created_on = mv_today - 6 )
      ( order_id = 'SO00000007' customer_id = 'C0007' order_date = mv_today - 5  created_on = mv_today - 5 )
      ( order_id = 'SO00000008' customer_id = 'C0008' order_date = mv_today - 4  created_on = mv_today - 4 )
      ( order_id = 'SO00000009' customer_id = 'C0001' order_date = mv_today - 3  created_on = mv_today - 3 )
      ( order_id = 'SO00000010' customer_id = 'C0003' order_date = mv_today - 2  created_on = mv_today - 2 ) ).

    lt_item = VALUE #( unit = 'ST' currency = 'EUR'
      ( order_id = 'SO00000001' item_no = '000010' product_id = 'P0001' quantity = 5 )
      ( order_id = 'SO00000001' item_no = '000020' product_id = 'P0002' quantity = 5 )
      ( order_id = 'SO00000002' item_no = '000010' product_id = 'P0003' quantity = 20 )
      ( order_id = 'SO00000002' item_no = '000020' product_id = 'P0004' quantity = 20 )
      ( order_id = 'SO00000003' item_no = '000010' product_id = 'P0004' quantity = 150 ) " quantity discount
      ( order_id = 'SO00000003' item_no = '000020' product_id = 'P0008' quantity = 10 )
      ( order_id = 'SO00000004' item_no = '000010' product_id = 'P0001' quantity = 8 )   " exceeds credit limit
      ( order_id = 'SO00000005' item_no = '000010' product_id = 'P0006' quantity = 4 )
      ( order_id = 'SO00000005' item_no = '000020' product_id = 'P0007' quantity = 2 )
      ( order_id = 'SO00000006' item_no = '000010' product_id = 'P0010' quantity = 120 ) " not enough stock
      ( order_id = 'SO00000007' item_no = '000010' product_id = 'P0002' quantity = 4 )
      ( order_id = 'SO00000007' item_no = '000020' product_id = 'P0005' quantity = 3 )
      ( order_id = 'SO00000007' item_no = '000030' product_id = 'P0009' quantity = 10 )
      ( order_id = 'SO00000008' item_no = '000010' product_id = 'P0009' quantity = 5 )
      ( order_id = 'SO00000008' item_no = '000020' product_id = 'P0004' quantity = 5 )
      ( order_id = 'SO00000009' item_no = '000010' product_id = 'P0008' quantity = 15 )
      ( order_id = 'SO00000009' item_no = '000020' product_id = 'P0003' quantity = 10 )
      ( order_id = 'SO00000010' item_no = '000010' product_id = 'P0001' quantity = 3 )
      ( order_id = 'SO00000010' item_no = '000020' product_id = 'P0005' quantity = 2 ) ).

    " Copy the current sales price from the product master into each order item
    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).
      <ls_item>-unit_price = mt_products[ product_id = <ls_item>-product_id ]-sales_price.
    ENDLOOP.

    INSERT zerp_so_h FROM TABLE @lt_head.
    INSERT zerp_so_i FROM TABLE @lt_item.
    rv_count = lines( lt_head ).
  ENDMETHOD.

ENDCLASS.
