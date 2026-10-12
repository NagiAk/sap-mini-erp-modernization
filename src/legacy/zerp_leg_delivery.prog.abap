*&---------------------------------------------------------------------*
*& Report ZERP_LEG_DELIVERY
*& Nightly delivery run: create deliveries for new sales orders
*&---------------------------------------------------------------------*
REPORT zerp_leg_delivery.

TYPE-POOLS: slis.

TABLES: zerp_stock, zerp_dlv_h, zerp_dlv_i, zerp_stock_move.

DATA: it_orders TYPE zerp_so_h OCCURS 0 WITH HEADER LINE,
      it_items  TYPE zerp_so_i OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF it_log OCCURS 0,
        order_id(10),
        delivery_id(10),
        result(10),
        msg(60),
      END OF it_log.

DATA: g_ok(1),
      g_dlv_id(10),
      g_move_id(10),
      g_item_no(6) TYPE n,
      g_cnt_dlv    TYPE i,
      g_cnt_skip   TYPE i,
      g_cnt_c1(10),
      g_cnt_c2(10),
      g_title      TYPE lvc_title.

DATA: it_fcat TYPE slis_t_fieldcat_alv,
      wa_fcat TYPE slis_fieldcat_alv.

START-OF-SELECTION.
  SELECT * FROM zerp_so_h INTO TABLE it_orders
    WHERE status = 'N'
    ORDER BY order_id.

  LOOP AT it_orders.
    REFRESH it_items.
    SELECT * FROM zerp_so_i INTO TABLE it_items
      WHERE order_id = it_orders-order_id
      ORDER BY item_no.

    PERFORM check_stock.
    IF g_ok = space.
      g_cnt_skip = g_cnt_skip + 1.
      CONTINUE.
    ENDIF.

    PERFORM create_delivery.

    UPDATE zerp_so_h SET status = 'D'
      WHERE order_id = it_orders-order_id.
    COMMIT WORK.
  ENDLOOP.

  PERFORM show_alv.

*&---------------------------------------------------------------------*
FORM check_stock.
  g_ok = 'X'.
  LOOP AT it_items.
    SELECT SINGLE * FROM zerp_stock
      WHERE product_id = it_items-product_id.
    IF zerp_stock-quantity < it_items-quantity.
      g_ok = space.
      CLEAR it_log.
      it_log-order_id = it_orders-order_id.
      it_log-result   = 'SKIPPED'.
      CONCATENATE 'Not enough stock for' it_items-product_id
        INTO it_log-msg SEPARATED BY space.
      APPEND it_log.
      EXIT.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
FORM create_delivery.
  PERFORM get_next_delivery_id.

  CLEAR zerp_dlv_h.
  zerp_dlv_h-delivery_id   = g_dlv_id.
  zerp_dlv_h-order_id      = it_orders-order_id.
  zerp_dlv_h-customer_id   = it_orders-customer_id.
  zerp_dlv_h-delivery_date = sy-datum.
  zerp_dlv_h-status        = 'O'.
  INSERT zerp_dlv_h.

  g_item_no = 0.
  LOOP AT it_items.
    g_item_no = g_item_no + 10.
    CLEAR zerp_dlv_i.
    zerp_dlv_i-delivery_id = g_dlv_id.
    zerp_dlv_i-item_no     = g_item_no.
    zerp_dlv_i-order_item  = it_items-item_no.
    zerp_dlv_i-product_id  = it_items-product_id.
    zerp_dlv_i-unit        = it_items-unit.
    zerp_dlv_i-quantity    = it_items-quantity.
    INSERT zerp_dlv_i.

    SELECT SINGLE * FROM zerp_stock
      WHERE product_id = it_items-product_id.
    zerp_stock-quantity     = zerp_stock-quantity - it_items-quantity.
    zerp_stock-last_changed = sy-datum.
    UPDATE zerp_stock.

    PERFORM get_next_move_id.
    CLEAR zerp_stock_move.
    zerp_stock_move-move_id      = g_move_id.
    zerp_stock_move-product_id   = it_items-product_id.
    zerp_stock_move-move_type    = '601'.
    zerp_stock_move-unit         = it_items-unit.
    zerp_stock_move-quantity     = it_items-quantity.
    zerp_stock_move-move_date    = sy-datum.
    zerp_stock_move-ref_doc_type = 'DLV'.
    zerp_stock_move-ref_doc_id   = g_dlv_id.
    zerp_stock_move-created_by   = sy-uname.
    INSERT zerp_stock_move.
  ENDLOOP.

  g_cnt_dlv = g_cnt_dlv + 1.
  CLEAR it_log.
  it_log-order_id    = it_orders-order_id.
  it_log-delivery_id = g_dlv_id.
  it_log-result      = 'DELIVERED'.
  it_log-msg         = 'Delivery created, stock reduced'.
  APPEND it_log.
ENDFORM.

*&---------------------------------------------------------------------*
FORM get_next_delivery_id.
  DATA: l_max(10),
        l_num(8) TYPE n.

  SELECT MAX( delivery_id ) FROM zerp_dlv_h INTO l_max.
  l_num = l_max+2(8).
  l_num = l_num + 1.
  CONCATENATE 'DL' l_num INTO g_dlv_id.
ENDFORM.

*&---------------------------------------------------------------------*
FORM get_next_move_id.
  DATA: l_max(10),
        l_num(8) TYPE n.

  SELECT MAX( move_id ) FROM zerp_stock_move INTO l_max.
  l_num = l_max+2(8).
  l_num = l_num + 1.
  CONCATENATE 'SM' l_num INTO g_move_id.
ENDFORM.

*&---------------------------------------------------------------------*
FORM show_alv.
  PERFORM add_fcat USING 'ORDER_ID'    'Order'    12.
  PERFORM add_fcat USING 'DELIVERY_ID' 'Delivery' 12.
  PERFORM add_fcat USING 'RESULT'      'Result'   10.
  PERFORM add_fcat USING 'MSG'         'Message'  50.

  WRITE g_cnt_dlv  TO g_cnt_c1 LEFT-JUSTIFIED.
  WRITE g_cnt_skip TO g_cnt_c2 LEFT-JUSTIFIED.
  CONCATENATE 'Delivery run - delivered:' g_cnt_c1 'skipped:' g_cnt_c2
    INTO g_title SEPARATED BY space.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      i_grid_title       = g_title
      it_fieldcat        = it_fcat
    TABLES
      t_outtab           = it_log.
ENDFORM.

*&---------------------------------------------------------------------*
FORM add_fcat USING p_field p_text p_len.
  CLEAR wa_fcat.
  wa_fcat-fieldname = p_field.
  wa_fcat-seltext_m = p_text.
  wa_fcat-outputlen = p_len.
  APPEND wa_fcat TO it_fcat.
ENDFORM.
