CREATE OR REPLACE FUNCTION update_task_time_bot(
  p_profile_id UUID,
  p_keyword TEXT,
  p_new_start_time TIMESTAMPTZ,
  p_new_due_time TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  v_task_id INT8;
  v_task_title TEXT;
BEGIN
  SELECT id, title INTO v_task_id, v_task_title
  FROM task
  WHERE profile_id = p_profile_id
    AND status = 0
    AND title ILIKE '%' || p_keyword || '%'
  ORDER BY start_time ASC
  LIMIT 1;

  IF v_task_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Không tìm thấy công việc nào khớp với từ khóa: ' || p_keyword);
  END IF;

  UPDATE task
  SET start_time = p_new_start_time,
      due_time = p_new_due_time,
      template_id = NULL
  WHERE id = v_task_id;

  RETURN json_build_object(
    'success', true,
    'task_id', v_task_id,
    'message', 'Đã dời lịch công việc "' || v_task_title || '"'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;