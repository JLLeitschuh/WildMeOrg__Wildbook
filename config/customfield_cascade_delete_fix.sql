
alter table "APICUSTOMFIELDS_CUSTOMFIELDVALUES" drop constraint "APICUSTOMFIELDS_CUSTOMFIELDVALUES_FK1", add constraint "APICUSTOMFIELDS_CUSTOMFIELDVALUES_FK1" FOREIGN KEY ("ID_EID") REFERENCES "CUSTOMFIELDVALUE"("ID") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED ;

