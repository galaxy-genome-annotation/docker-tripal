CREATE function find_features(argOrgName varchar, argRefseq text, argSoType text, argFmin int, argFmax int) returns setof feature as $$
SELECT
    feature.feature_id, feature.dbxref_id, feature.organism_id,
    feature.name, feature.uniquename, feature.residues, feature.seqlen,
    feature.md5checksum, feature.type_id, feature.is_analysis,
    feature.is_obsolete, feature.timeaccessioned, feature.timelastmodified
FROM
    feature, featureloc, cvterm
WHERE
    -- Join conditions
    feature.feature_id = featureloc.feature_id AND
    feature.type_id = cvterm.cvterm_id AND
    -- Actual conditions
    -- only in organism
    feature.organism_id = (select organism_id from organism where common_name=argOrgName)
    AND
    -- with queried seqid
    (featureloc.srcfeature_id IN (SELECT feature_id FROM feature WHERE name = argRefseq))
    AND
    -- within queried region
    (featureloc.fmin <= argFmax AND argFmin <= featureloc.fmax)
    AND
    -- top level only
    cvterm.name = argSoType
$$ language sql stable;

CREATE function find_sequence(argOrgName varchar, argRefseq text, argFmin int, argFlen int) returns text as $$
SELECT
    substring(
        (
            SELECT
                residues
            FROM
                feature
            WHERE
                feature.organism_id = (select organism_id from organism where common_name=argOrgName)
                AND
                feature.uniquename = argRefSeq
        )
        from argFmin for argFlen
    ) as "sequence"
;
$$ language sql stable;
