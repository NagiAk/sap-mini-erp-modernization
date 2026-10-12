*&---------------------------------------------------------------------*
*& Report ZERP_LEG_ORDER_UPLOAD
*& Upload sales orders from interface file
*&---------------------------------------------------------------------*
REPORT zerp_leg_order_upload.

TABLES: zerp_customer, zerp_product, zerp_so_h, zerp_so_i.

DATA: BEGIN OF it_file OCCURS 0,
        line(255),
      END OF it_file.

DATA: BEGIN OF it_rec OCCURS 0,
        order_ref(20),
        customer_id(10),
        order_date(8),
        product_id(10),
        quantity(20),
      END OF it_rec.

DATA: BEGIN OF it_log OCCURS 0,
        order_ref(20),
        order_id(10),
        msg(60),
      END OF it_log.

DATA: g_last_ref(20),
      g_order_id(10),
      g_item_no(6)  TYPE n,
      g_qty         TYPE p DECIMALS 3,
      g_skip(1),
      g_count_ord   TYPE i,
      g_count_err   TYPE i.

PARAMETERS: p_file(128) TYPE c DEFAULT '/tmp/zerp_in/orders.csv' LOWER CASE.

START-OF-SELECTION.
  PERFORM read_file.
  PERFORM split_lines.
  PERFORM create_orders.
  PERFORM write_log.

*&---------------------------------------------------------------------*
FORM read_file.
  OPEN DATASET p_file FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  DO.
    READ DATASET p_file INTO it_file-line.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
    APPEND it_file.
  ENDDO.
  CLOSE DATASET p_file.

  IF sy-uname = 'DEVELOPER'.
    DESCRIBE TABLE it_file LINES sy-tfill.
    WRITE: / 'DEBUG lines read:', sy-tfill.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
FORM split_lines.
  LOOP AT it_file.
    IF sy-tabix = 1.
      CONTINUE.
    ENDIF.
    CLEAR it_rec.
    SPLIT it_file-line AT ';' INTO it_rec-order_ref it_rec-customer_id
          it_rec-order_date it_rec-product_id it_rec-quantity.
    APPEND it_rec.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
FORM create_orders.
  SORT it_rec BY order_ref.

  LOOP AT it_rec.
    IF it_rec-order_ref <> g_last_ref.
      g_last_ref = it_rec-order_ref.
      g_skip = space.

      SELECT SINGLE * FROM zerp_customer
        WHERE customer_id = it_rec-customer_id.
      IF sy-subrc <> 0.
        g_skip = 'X'.
        CLEAR it_log.
        it_log-order_ref = it_rec-order_ref.
        it_log-msg = 'Customer not found - order skipped'.
        APPEND it_log.
        g_count_err = g_count_err + 1.
        CONTINUE.
      ENDIF.

      PERFORM get_next_order_id.

      CLEAR zerp_so_h.
      zerp_so_h-order_id    = g_order_id.
      zerp_so_h-customer_id = it_rec-customer_id.
      zerp_so_h-order_date  = it_rec-order_date.
      zerp_so_h-status      = 'N'.
      zerp_so_h-currency    = 'EUR'.
      zerp_so_h-created_by  = sy-uname.
      zerp_so_h-created_on  = sy-datum.
      INSERT zerp_so_h.

      g_item_no = 0.
      g_count_ord = g_count_ord + 1.
      CLEAR it_log.
      it_log-order_ref = it_rec-order_ref.
      it_log-order_id  = g_order_id.
      it_log-msg       = 'Order created'.
      APPEND it_log.
    ENDIF.

    IF g_skip = 'X'.
      CONTINUE.
    ENDIF.

    SELECT SINGLE * FROM zerp_product
      WHERE product_id = it_rec-product_id.

    CATCH SYSTEM-EXCEPTIONS conversion_errors = 1.
      g_qty = it_rec-quantity.
    ENDCATCH.
    IF sy-subrc = 1.
      g_qty = 0.
    ENDIF.

    g_item_no = g_item_no + 10.
    CLEAR zerp_so_i.
    zerp_so_i-order_id   = g_order_id.
    zerp_so_i-item_no    = g_item_no.
    zerp_so_i-product_id = it_rec-product_id.
    zerp_so_i-unit       = 'ST'.
    zerp_so_i-quantity   = g_qty.
    zerp_so_i-unit_price = zerp_product-sales_price.
    zerp_so_i-currency   = 'EUR'.
    INSERT zerp_so_i.

    COMMIT WORK.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
FORM get_next_order_id.
  DATA: l_max(10),
        l_num(8) TYPE n.

  SELECT MAX( order_id ) FROM zerp_so_h INTO l_max.
  l_num = l_max+2(8).
  l_num = l_num + 1.
  CONCATENATE 'SO' l_num INTO g_order_id.
ENDFORM.

*&---------------------------------------------------------------------*
FORM write_log.
  WRITE: / 'Order upload finished'.
  WRITE: / 'Orders created:', g_count_ord.
  WRITE: / 'Errors:        ', g_count_err.
  ULINE.
  LOOP AT it_log.
    WRITE: / it_log-order_ref, it_log-order_id, it_log-msg.
  ENDLOOP.
ENDFORM.
