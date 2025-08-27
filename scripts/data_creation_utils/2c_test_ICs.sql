SET search_path TO sdss_relational_2x;

ALTER TABLE specobjall		ADD PRIMARY KEY (specobjid);
ALTER TABLE zoospec 			ADD PRIMARY KEY (specobjid);
ALTER TABLE galspecextra	ADD PRIMARY KEY (specobjid);
ALTER TABLE galspecindx		ADD PRIMARY KEY (specobjid);
ALTER TABLE platex				ADD PRIMARY KEY (plateid);
ALTER TABLE photoobjall		ADD PRIMARY KEY (objid);
ALTER TABLE photoz				ADD PRIMARY KEY (objid);
ALTER TABLE field					ADD PRIMARY KEY (fieldid);
ALTER TABLE frame 				ADD COLUMN frameid BIGINT GENERATED ALWAYS AS IDENTITY;
ALTER TABLE frame					ADD PRIMARY KEY (frameid); 

ALTER TABLE specobjall 		ADD FOREIGN KEY (bestObjID) REFERENCES photoobjall(objid);
ALTER TABLE specobjall 		ADD FOREIGN KEY (plateID) REFERENCES platex(plateid);
ALTER TABLE zoospec		 		ADD FOREIGN KEY (specObjID) REFERENCES specobjall(specObjID);
ALTER TABLE galspecextra	ADD FOREIGN KEY (specObjID) REFERENCES specobjall(specObjID);
ALTER TABLE galspecindx		ADD FOREIGN KEY (specObjID) REFERENCES specobjall(specObjID);
ALTER TABLE photoz		 		ADD FOREIGN KEY (objid) REFERENCES photoobjall(objid);
ALTER TABLE photoobjall		ADD FOREIGN KEY (fieldid) REFERENCES field(fieldid);
ALTER TABLE frame					ADD FOREIGN KEY (fieldid) REFERENCES field(fieldid);

