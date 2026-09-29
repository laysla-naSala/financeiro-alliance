-- Arquivos (extratos e anexos) guardados para ir junto no e-mail da contabilidade.
-- Pasta privada: só quem tem perfil lê; 'lanca' e 'admin' enviam e substituem. Só cria; não altera nada existente.

insert into storage.buckets (id, name, public) values ('documentos', 'documentos', false);

create policy "documentos: quem tem perfil lê" on storage.objects for select to authenticated
  using ( bucket_id = 'documentos' and (select private.papel_atual()) in ('admin','lanca','consulta') );

create policy "documentos: lança e admin enviam" on storage.objects for insert to authenticated
  with check ( bucket_id = 'documentos' and (select private.papel_atual()) in ('admin','lanca') );

create policy "documentos: lança e admin substituem" on storage.objects for update to authenticated
  using ( bucket_id = 'documentos' and (select private.papel_atual()) in ('admin','lanca') )
  with check ( bucket_id = 'documentos' and (select private.papel_atual()) in ('admin','lanca') );

create policy "documentos: lança e admin removem" on storage.objects for delete to authenticated
  using ( bucket_id = 'documentos' and (select private.papel_atual()) in ('admin','lanca') );
