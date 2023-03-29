Create role adm;
select rolname from pg_roles;

Create role administrator with superuser;
select rolname from pg_roles;

create role visitor with NOSUPERUSER;
select rolname from pg_roles;